require "sinatra"
require "json"
require "mongo"

require "cloud_foundry_environment"
require "benchmark"

class ExampleApp < Sinatra::Application
  before do
    content_type "text/plain"
  end

  post "/:collection" do
    # nothing
  end

  delete "/:collection" do
    collection_name = params[:collection]
    mongodb_client[collection_name].drop
    "DELETED " + collection_name
  end

  get "/:collection/:key" do
    collection_name = params[:collection]
    key = params[:key]
    collection = mongodb_client[collection_name]
    item = collection.find("key" => key).first
    halt 404 if item.nil?
    item["value"]
  end

  get "/benchmark/:collection/:key" do
    collection_name = params[:collection]
    key = params[:key]
    time_spent = Benchmark.measure {
      benchmark_length.times {
        collection = mongodb_client[collection_name]
        item = collection.find("key" => key).first
      }
    }
    time_spent.to_s
  end

  post "/:collection/:key/:value" do
    collection_name = params[:collection]
    key = params[:key]
    value = params[:value]

    mongodb_client[collection_name].update_one(
      {'key' => key}, {'key' => key, 'value' => value},
      upsert: true
    )

    status 201
  end

  post "/benchmark/:collection/:key/:value" do
    collection_name = params[:collection]
    key = params[:key]
    value = params[:value]

    time_spent = Benchmark.measure {
      benchmark_length.times {
        mongodb_client[collection_name].update_one(
          {'key' => key}, {'key' => key, 'value' => value},
          upsert: true
        )
      }
    }

    time_spent.to_s
  end

  def tell_user_collection_not_found
    halt 404
  end

  def tell_user_how_to_bind
    bind_instructions = %{
      You must bind a MongoDB service instance to this application.

      You can run the following commands to create an instance and bind to it:

        $ cf create-service mongodb default mongodb-instance
        $ cf bind-service app-name mongodb-instance
    }
    halt 500, bind_instructions
  end

  private

  def cloud_foundry_environment
    @cloud_foundry_environment ||= CloudFoundryEnvironment.new
  end

  def mongodb_client
    @mongodb_client ||= Mongo::Client.new(cloud_foundry_environment.mongo_uri, ssl: true, ssl_verify: false)
  end

  def benchmark_length
    @benchmark_length ||= cloud_foundry_environment.benchmark_length
  end

end
