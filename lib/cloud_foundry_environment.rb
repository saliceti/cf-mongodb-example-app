class CloudFoundryEnvironment
  NoMongodbBoundError = Class.new(StandardError)

  def initialize(services = ENV.to_h.fetch("VCAP_SERVICES"))
    @services = JSON.parse(services)
  end

  def mongo_uri
    if services.has_key?("p-mongodb")
      services.fetch("p-mongodb").first.fetch("credentials").fetch("uri")
    elsif services.has_key?("user-provided")
      services.fetch("user-provided").first.fetch("credentials").fetch("uri")
    else
      raise NoMongodbBoundError
    end

    rescue KeyError => e
      puts e.message
      raise NoMongodbBoundError
  end

  def benchmark_length
    ENV.to_h.fetch("BENCHMARK_LENGTH", "100").to_i
  end

  private

  attr_reader :services
end
