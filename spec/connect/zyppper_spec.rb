require 'spec_helper'

describe SUSE::Connect::Zypper do

  before(:each) do
    Object.stub(:system => true)
  end

  subject { SUSE::Connect::Zypper }

  describe '.installed_products' do

    context :sle11 do
      context :sp3 do

        let(:xml) { File.read('spec/fixtures/product_valid_sle11sp3.xml') }

        before do
          Object.should_receive(:'`').with(include 'zypper').and_return(xml)
        end

        it 'returns valid list of products based on proper XML' do
          subject.installed_products.first[:name].should eq 'SUSE_SLES'
        end

        it 'returns valid version' do
          subject.installed_products.first[:version].should eq '11.3'
        end

        it 'returns valid arch' do
          subject.installed_products.first[:arch].should eq 'x86_64'
        end

        it 'returns proper base product' do
          subject.base_product[:name].should eq 'SUSE_SLES'
        end

      end
    end

    context :sle12 do
      context :sp0 do

        let(:xml) { File.read('spec/fixtures/product_valid_sle12sp0.xml') }

        before do
          Object.should_receive(:'`').with(include 'zypper').and_return(xml)
        end

        it 'returns valid name' do
          subject.installed_products.first[:name].should eq 'SLES'
        end

        it 'returns valid version' do
          subject.installed_products.first[:version].should eq '12'
        end

        it 'returns valid arch' do
          subject.installed_products.first[:arch].should eq 'x86_64'
        end

        it 'returns proper base product' do
          subject.base_product[:name].should eq 'SLES'
        end

      end
    end

  end

  describe '.add_service' do

    it 'calls zypper with proper arguments' do
      parameters = "zypper --quiet --non-interactive addservice -t ris http://example.com 'branding'"
      Object.should_receive(:system).with(parameters).and_return(true)
      subject.add_service('branding', 'http://example.com')
    end

  end

  describe '.remove_service' do

    it 'calls zypper with proper arguments' do
      parameters = "zypper --quiet --non-interactive removeservice 'branding'"
      Object.should_receive(:system).with(parameters).and_return(true)
      subject.remove_service('branding')
    end

  end

  describe '.refresh' do

    it 'calls zypper with proper arguments' do
      Object.should_receive(:system).with('zypper refresh').and_return(true)
      subject.refresh
    end

  end

  describe '.enable_service_repository' do

    it 'calls zypper with proper arguments' do
      parameters = "zypper --quiet modifyservice --ar-to-enable 'branding:tofu' 'branding'"
      Object.should_receive(:system).with(parameters).and_return(true)
      subject.enable_service_repository('branding', 'tofu')
    end

  end

  describe '.disable_repository_autorefresh' do

    it 'calls zypper with proper arguments' do
      parameters = "zypper --quiet modifyrepo --no-refresh 'branding:tofu'"
      Object.should_receive(:system).with(parameters).and_return(true)
      subject.disable_repository_autorefresh('branding', 'tofu')
    end

  end

  describe '?write_credentials_file' do

    mock_dry_file

    context :credentials_folder_exist do

      before(:each) do
        Dir.should_receive(:exists?).with(ZYPPER_CREDENTIALS_DIR).and_return true
      end

      it 'will not create credentials.d folder' do
        Dir.should_not_receive(:mkdir).with(ZYPPER_CREDENTIALS_DIR)
        subject.send(:write_credentials_file, *params)
      end

      it 'should produce a log record in case of Exception' do
        source_cred_file.stub(:puts).and_raise(IOError)
        Logger.should_receive(:error)
        subject.send(:write_credentials_file, *params)
      end

    end

    context :credentials_folder_not_exist do

      before(:each) do
        Dir.should_receive(:exists?).with(System::ZYPPER_CREDENTIALS_DIR).and_return false
      end

      it 'creates credentials.d folder' do
        Dir.should_receive(:mkdir).with(System::ZYPPER_CREDENTIALS_DIR)
        subject.send(:write_credentials_file, *params)
      end

    end

    it 'opens a file for writing with name of service' do
      File.should_receive(:open).with('/etc/zypp/credentials.d/ha', 'w')
      subject.send(:write_credentials_file, *params)
    end

    it 'writes a file with corresponding product credentials' do
      source_cred_file.should_receive(:puts).with('username=SCC_Kif')
      source_cred_file.should_receive(:puts).with('password=Kroker')
      subject.send(:write_credentials_file, *params)
    end

    it 'closes a file for credentials' do
      source_cred_file.should_receive(:close)
      subject.send(:write_credentials_file, *params)
    end

  end

  describe '?sccized_login' do

    it 'should prepend login with SCC_ unless it already there' do
      subject.send(:sccized_login, 'bender').should eq 'SCC_bender'
    end

    it 'should return login if in is prefixed with SCC' do
      subject.send(:sccized_login, 'SCC_kif').should eq 'SCC_kif'
    end

  end

  describe '.base_product' do

    let :parsed_products do
      [
        { :isbase => '1', :name => 'SLES', :productline => 'SLE_productline1', :registerrelease => '' },
        { :isbase => '2', :name => 'Cloud', :productline => 'SLE_productline2', :registerrelease => '' }
      ]
    end

    before do
      subject.stub(:installed_products => parsed_products)
    end

    it 'should return first product from installed product which is base' do
      subject.base_product.should eq(parsed_products.first)
    end

    it 'should set release_type to one extracted' do
      subject.should_receive(:lookup_product_release).and_return('NCR')
      subject.base_product[:release_type].should eq 'NCR'
    end

    context :oem_file_exists do

      it 'should extract product_release from OEM file if exists' do
        File.should_receive(:exists?).with(subject::OEM_PATH + '/SLE_productline1').and_return(true)
        File.should_receive(:readlines).with(subject::OEM_PATH + '/SLE_productline1').and_return(["ABC\n"])
        subject.base_product[:release_type].should eq 'ABC'
      end

    end

    context :registerrelease_defined do

      it 'should extract product_release from registerrelease attribute of product' do
        File.should_receive(:exists?).with(subject::OEM_PATH + '/SLE_productline1').and_return(false)
        subject.stub(:installed_products => [
            { :registerrelease => 'DDD', :isbase => '1', :name => 'SLES', :productline => 'SLE_productline1' }
        ])
        subject.base_product[:release_type].should eq 'DDD'
      end

    end

    context :flavor_defined do

      it 'should extract product_release from flavor file if exists' do
        File.should_receive(:exists?).with(subject::OEM_PATH + '/SLE_productline1').and_return(false)
        subject.stub(:installed_products => [
            {
              :flavor          => 'ZZZ',
              :isbase          => '1',
              :name            => 'SLES',
              :productline     => 'SLE_productline1',
              :registerrelease => ''
            }
        ])
        subject.base_product[:release_type].should eq 'ZZZ'
      end

    end

  end

  describe '.write_base_credentials' do

    mock_dry_file

    it 'should call write_credentials_file' do
      subject.should_receive(:write_credentials_file).with('dummy', 'tummy', 'SCCcredentials')
      subject.write_base_credentials('dummy', 'tummy')
    end

  end

  describe '.write_service_credentials' do

    mock_dry_file

    it 'extracts username and password from system credentials' do
      System.should_receive(:credentials)
      subject.write_service_credentials('turbo')
    end

    it 'creates a file with source name' do
      subject.should_receive(:write_credentials_file).with('dummy', 'tummy', 'turbo')
      subject.write_service_credentials('turbo')
    end

  end

  describe '.distro_target' do
    it 'return zypper targetos output' do
      Object.should_receive(:'`').with('zypper targetos').and_return('openSUSE-13.1-x86_64')
      Zypper.distro_target.should eq 'openSUSE-13.1-x86_64'
    end
  end

end
