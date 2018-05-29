require 'yaml'

describe "cloudinit-files" do

  let(:module_path) { File.expand_path("aws/cloudinit/modules/cloudinit-files", repo_dir)}

  describe "generates cloudinit config for uploading files" do

    it "handles empty files list" do
      tf = <<~EOF
        module "test" {
          source = "#{module_path}"
          files = []
        }
        
        output "result" {
          value = "${module.test.rendered}"
        }
      EOF
      output = terraform(tf)
      value = output['result']['value']
      expect(value).to include("write_files:\n\n")
      expect(YAML.load(value)['write_files']).to be_nil
    end

    it "generates files list for single file" do
      tf = <<~EOF
        module "test" {
          source = "#{module_path}"
          files = [
            {
              path = "/tmp/foo.txt"
              content = "bar"
              owner = "foo:bar"
              permissions = "0777"
            }
          ]
        }
        
        output "result" {
          value = "${module.test.rendered}"
        }
      EOF
      output = terraform(tf)
      yml = YAML.load(output['result']['value'])

      expect(yml['write_files'].size).to be 1
      expect(yml['write_files'].first['path']).to eq("/tmp/foo.txt")
      expect(yml['write_files'].first['content']).to eq("bar\n")
      expect(yml['write_files'].first['owner']).to eq("foo:bar")
      expect(yml['write_files'].first['permissions']).to eq("0777")
    end

    it "generates files list with defaults" do
      tf = <<~EOF
        module "test" {
          source = "#{module_path}"
          files = [
            {
              path = "/tmp/foo.txt"
              content = "bar"
            }
          ]
        }
        
        output "result" {
          value = "${module.test.rendered}"
        }
      EOF
      output = terraform(tf)
      yml = YAML.load(output['result']['value'])

      expect(yml['write_files'].size).to be 1
      expect(yml['write_files'].first['path']).to eq("/tmp/foo.txt")
      expect(yml['write_files'].first['content']).to eq("bar\n")
      expect(yml['write_files'].first['owner']).to eq("root:root")
      expect(yml['write_files'].first['permissions']).to eq("0644")
    end

    it "generates files list for multiple file" do
      tf = <<~EOF
        module "test" {
          source = "#{module_path}"
          files = [
            {
              path = "/tmp/foo.txt"
              content = "bar"
              owner = "foo:bar"
              permissions = "0777"
            },
            {
              path = "/tmp/bar.txt"
              content = "baz"
            }
          ]
        }
        
        output "result" {
          value = "${module.test.rendered}"
        }
      EOF
      output = terraform(tf)
      yml = YAML.load(output['result']['value'])

      expect(yml['write_files'].size).to be 2
      expect(yml['write_files'][0]['path']).to eq("/tmp/foo.txt")
      expect(yml['write_files'][1]['path']).to eq("/tmp/bar.txt")
    end

  end
end
