JOB_DIR = '/Users/Shared/Jenkins/Home/jobs/%s/'
LOG_NAME = '/Users/Shared/Jenkins/Home/jobs/%s/builds/%s/log'
JENKINS_URL = 'http://localhost:8080'


require 'open-uri'

def tail(filepath, &block)
  fpointer = 0
  sleep 0.5 until File.exists?(filepath)

  begin
    f = open(filepath, 'r')
    while true
      yield f.read
      sleep 0.5
      fpointer = f.pos
    end
  rescue EOFError
    f.close unless f.closed?
    # 更新を検知するまで待つ
    closetime = File.size(filepath)
    while (File.size(filepath) == closetime)
      sleep 0.5
    end
    f = open(filepath)
    f.seek(fpointer, IO::SEEK_SET)
    retry
  end
end

class WebSocketApp < Rack::WebSocket::Application
  def initialize(options = {})
    super
  end

  def on_open(env)
    params = Rack::Utils.parse_nested_query(env["QUERY_STRING"])

    filename = LOG_NAME % [params['job'], params['build']]
    @thread = Thread.start do
      begin
        tail(filename) do |data|
          send_data data
        end
      rescue => e
        p e
        puts e.backtrace.join("\n")
      end
    end

  end

  def on_close(env)
    puts "Client Disconnected"
    @thread.kill if @thread
  end

  def on_message(env, message)
    puts "Received message: #{message}"

    send_data "@client I received your message: #{message}<br/>"
  end

  def on_error(env, error)
    puts "Error occured: " + error.message
  end

end

class SinatraApp < Sinatra::Application
  get '/jobs/:job' do
    redirect to('/jobs/%s/' % [params[:job]])
  end

  get '/jobs/:job/' do
    last_build = open("%s/nextBuildNumber" % (JOB_DIR % params[:job])).read.to_i - 1
    erb :job, :locals => {:job => params[:job], :last_build => last_build }
  end

  get '/jobs/:job/run' do
    build = open("%s/nextBuildNumber" % (JOB_DIR % params[:job])).read
    open("%s/job/%s/build?delay=0sec" % [JENKINS_URL, params[:job]]).read
    redirect to('/jobs/%s/%s' % [params[:job], build])
  end

  get '/jobs/:job/:build' do
    erb :log, :locals => {:job => params[:job], :build => params[:build] }
  end
end

