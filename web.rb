require 'docker'
require 'sinatra'
require 'erb'

IMAGES = {
  'sshd' => {'Cmd' => ['/usr/sbin/sshd', '-D'], 'Image' => 'kurochan/ubuntu-sshd', 'PortSpecs' => '22', 'ExposedPorts' => ['22/tcp']},
  'Apache' => {'Cmd' => ['/apache.sh', '-D'], 'Image' => 'kurochan/ubuntu-apache2', 'PortSpecs' => '80', 'ExposedPorts' => ['80/tcp']},
}
ENV['DOCKER_URL'] = 'tcp://localhost:4243'

get '/' do
  @container = Docker::Container.all.reverse
  @images = IMAGES
  erb :index
end

post '/start' do
  return 'Error' unless params['image']
  start_container IMAGES[params['image']]
  redirect '/'
end

post '/stop' do
  return 'Error' unless params['id']
  stop_container params['id']
  redirect '/'
end

get '/*/' do |path|
  raise Sinatra::NotFound unless File.exist?(settings.public_folder + '/' +  path + '/index.html')
  send_file File.join(settings.public_folder, path, 'index.html')
end

def start_container(image)
  container = Docker::Container.create(image)
  container.start('PortBindings' => {image['ExposedPorts'][0] => [{'HostIp' => '0.0.0.0'}]})
end

def stop_container(id)
  container = Docker::Container.get(id)
  container.stop
end
