module Restfulie
  module Client
    module HTTP #:nodoc:
      # ==== RequestHistory
      # Uses RequestBuilder and remind previous requests
      #
      # ==== Example:
      #
      #   @executor = ::Restfulie::Client::HTTP::RequestHistoryExecutor.new("http://restfulie.com") #this class includes RequestHistory module.
      #   @executor.at('/posts').as('application/xml').accepts('application/atom+xml').with('Accept-Language' => 'en').get.code #=> 200 #first request
      #   @executor.at('/blogs').as('application/xml').accepts('application/atom+xml').with('Accept-Language' => 'en').get.code #=> 200 #second request
      #   @executor.request_history!(0) #doing first request
      #
      class RequestHistory < MasterDelegator
        
        def initialize(requester)
          @requester = requester
        end

        def snapshots
          @snapshots ||= []
        end

        def max_to_remind
          10
        end
        
        def request!(method=nil, path=nil, *args)#:nodoc:
          if method == nil || path == nil 
            raise 'History not selected' unless @snapshot
            delegate (:request!, @snapshot[:method], @snapshot[:path], *@snapshot[:args] )
          else
            @snapshot = make_snapshot(method, path, *args)
            unless snapshots.include?(@snapshot)
              snapshots.shift if snapshots.size >= max_to_remind
              snapshots << @snapshot
            end
            delegate :request!, method, path, *args
          end
        end

        def request(method = nil, path = nil, *args)
          begin
            request!(method, path, *args) 
          rescue Restfulie::Client::HTTP::Error::RESTError => se
            se
          end
        end
        
        def history(number)
          @snapshot = snapshots[number]
          raise "Undefined snapshot for #{number}" unless @snapshot
          self.host    = @snapshot[:host]
          self.cookies = @snapshot[:cookies]
          self.headers = @snapshot[:headers]
          self.default_headers = @snapshot[:default_headers]
          at(@snapshot[:path])
        end

        private

        def make_snapshot(method, path, *args)
          arguments = args.dup
          cutom_headers = arguments.extract_options!
          { :host            => self.host.dup,
            :default_headers => self.default_headers.dup,
            :headers         => self.headers.dup,
            :cookies         => self.cookies,
            :method          => method, 
            :path            => path,
            :args            => arguments << self.headers.merge(cutom_headers)   }
        end
      end
    end
  end
end
