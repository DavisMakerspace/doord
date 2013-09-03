module Sentry

  class Server
    attr_reader :door, :secrets
    def initialize(door, json_server, secrets)
      @door = door
      @json_server = json_server
      @secrets = secrets
      @subscribers = []
      @mutex = Mutex.new
    end
    def run()
      threads = []
      threads << Thread.new { self.monitor }
      threads << Thread.new { self.get_clients }
      threads.each { |thr| thr.join }
    end
    def subscribe(client)
      @mutex.synchronize { @subscribers << client }
    end
    def unsubscribe(client)
      @mutex.synchronize { @subscribers.delete client }
    end
    def get_clients()
      @json_server.run do |json_client|
        Thread.new { Client.new(self, json_client).run }
      end
    end
    def monitor()
      @door.monitor() do |type, value|
        msg = {type => value}
        $LOG.info { "#{type} #{value.inspect}" }
        @mutex.synchronize do
          @subscribers.each { |c| c.send msg }
        end
      end
    end
  end

  class Client
    def initialize(server, json_client)
      @server = server
      @json_client = json_client
      @ids = @json_client.socket.uids
      @id = @ids ? @ids[0] : nil
      @user = nil
      $LOG.info { "#{@id} has connected" }
    end
    def run()
      send({banner: "Welcome client #{@id}"})
      @server.subscribe self
      @json_client.receive do |msg|
        case msg[:action]
        when "auth"
          user = msg[:user].to_s
          @user = @server.secrets.auth?({client: @id, user: user}, msg[:secret]) ? user : nil
          send({class: :auth, user: @user})
        when "lock"
          if !@user
            send({error: "Not authorized to lock"})
          elsif @server.door.opened?
            send({error: "Door open; cannot lock"})
          elsif @server.door.locked?
            send({warning: "Already locked"})
          else
            send({ack: "Sending lock signal"})
            @server.door.lock
          end
        when "unlock"
          if !@user
            send({error: "Not authorized to unlock"})
          elsif @server.door.locked? === false
            send({warning: "Already unlocked"})
          else
            send({ack: "Sending unlock signal"})
            @server.door.unlock
          end
        when nil
        else
          send({error: "Unknown action type"})
        end
        case msg[:status]
        when "opened"
          send({opened: @server.door.opened?})
        when "locked"
          send({locked: @server.door.locked?})
        when nil
        else
          send({error: "Unknown status type"})
        end
      end
      @server.unsubscribe self
      $LOG.info { "#{@id} has disconnected" }
    end
    def send(msg)
      @json_client.send msg
    end
  end

end
