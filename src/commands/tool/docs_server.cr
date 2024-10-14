module Mint
  class Cli < Admiral::Command
    class DocsServer < Admiral::Command
      include Command

      define_help description: "Generates API Documentation."

      define_flag host : String,
        description: "The host to serve the documentation on.",
        default: ENV["HOST"]? || "0.0.0.0",
        short: "h"

      define_flag port : Int32,
        description: "The port to serve the documentation on.",
        default: (ENV["PORT"]? || "3002").to_i,
        short: "p"

      def run
        execute "Generating documentation", check_dependencies: true do
          DocumentationServer.new(
            host: flags.host,
            port: flags.port)
        end
      end
    end
  end
end
