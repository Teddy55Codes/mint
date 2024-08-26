module Mint
  class Cli < Admiral::Command
    class Docs < Admiral::Command
      include Command

      define_help description: "Generates API Documentation"

      define_argument directory : String,
        description: "The directory to generate the docs to",
        default: "docs"

      define_flag include_packages : Bool,
        description: "If specified, documentation will be generated for used packages as well.",
        default: false

      define_flag include_core : Bool,
        description: "If specified, documentation will be generated for the standard library as well.",
        default: false

      def run
        execute "Documentation Generator" do
          directory =
            arguments.directory.not_nil! # There is a default above

          jsons = [MintJson.parse_current]
          jsons.concat(SourceFiles.packages) if flags.include_packages

          asts =
            jsons.map do |json|
              Ast.new.tap do |ast|
                json.source_files.each do |file|
                  ast.merge(Parser.parse(File.read(file), file))
                end
              end
            end

          asts << Core.ast if flags.include_core

          terminal.measure %(#{COG} Clearing the "#{directory}" directory...) do
            FileUtils.rm_rf directory
            Dir.mkdir directory
          end

          terminal.measure "#{COG} Generating documentation..." do
            StaticDocumentationGenerator
              .generate(asts)
              .each { |path, contents| File.write_p(Path[directory, path], contents) }
          end
        end
      end
    end
  end
end
