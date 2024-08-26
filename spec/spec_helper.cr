require "spec"

ENV["SPEC"] = "TRUE"
MINT_ENV["TEST"] = "TRUE"

require "./spec_helpers"
require "../src/all"

# Mock things
class Mint::Installer::Repository
  @terminal = Render::Terminal.new

  def terminal
    @terminal
  end

  def output
    terminal.io.to_s.uncolorize
  end

  def run(command, chdir = directory)
    content =
      case command.split(' ')[1]
      when "tag"
        "0.1.0\n0.2.0"
      when "fetch"
        "fetched"
      when "checkout"
        "checked out"
      when "clone"
        "cloned"
      else
        ""
      end

    if url == "error"
      {Process::Status.new(1), "", content}
    else
      {Process::Status.new(0), content, ""}
    end
  end
end

macro subject(method)
  subject = ->(sample : String) {
    Mint::Parser.new(sample, "TestFile.mint").{{method}}
  }
end

macro expect_ok(sample)
  it "Parses: " + {{"#{sample}"}} do
    result = subject.call({{sample}})
    result.should_not be_nil
    result.should be_a(Mint::Ast::Node)
  end
end

macro expect_ignore(sample)
  it {{"#{sample}"}} do
    subject.call({{sample}}).should be_nil
  end
end

macro expect_error(sample, error)
  it {{"#{sample}"}} do
    expect_raises({{error}}) do
      subject.call({{sample}})
    end
  end
end

module LSP
  class Server
    def log(message)
    end
  end
end

class Workspace
  @files = {} of String => File
  @id : String

  def workspace
    Mint::Workspace[File.join(@root, "test.file")]
  end

  def initialize
    @id =
      Random.new.hex(5)

    @root =
      File.join(Dir.tempdir, @id)

    Dir.mkdir(@root)

    file("mint.json", {
      "name"               => "test",
      "source-directories" => [
        ".",
      ],
    }.to_json)
  end

  def file(name, contents) : File
    file =
      File.new(File.join(@root, name), "w+")

    file.print(contents)
    file.flush

    @files[name] = file

    file
  end

  def root_path
    File.realpath(@root)
  end

  def file_path(name)
    "file://#{@files[name]?.try(&.path)}"
  end

  def cleanup
    @files.values.each(&.delete)
    Dir.delete(@root)
  end
end

def with_workspace(&)
  workspace = Workspace.new

  begin
    yield workspace
  ensure
    workspace.cleanup
  end
end

def notify_lsp(method, message)
  in_io =
    IO::Memory.new

  out_io =
    IO::Memory.new

  server =
    Mint::LS::Server.new(in_io, out_io)

  body = {
    jsonrpc: "2.0",
    params:  message,
    method:  method,
  }.to_json

  in_io.print "Content-Length: #{body.bytesize}\r\n\r\n#{body}"
  in_io.rewind

  server.read
end

def lsp(messages)
  in_io =
    IO::Memory.new

  out_io =
    IO::Memory.new

  server =
    Mint::LS::Server.new(in_io, out_io)

  messages.map do |item|
    # Clear out IOs so it's a fresh start
    out_io.clear
    in_io.clear

    body = {
      jsonrpc: "2.0",
      id:      item[:id],
      params:  item[:message],
      method:  item[:method],
    }.to_json

    in_io.print "Content-Length: #{body.bytesize}\r\n\r\n#{body}"
    in_io.rewind # Rewind in IO so the server can read it

    # Process the message
    server.read

    LSP::MessageParser.parse(out_io.rewind) { |content| content }
  end
end

def lsp_json(messages)
  in_io =
    IO::Memory.new

  out_io =
    IO::Memory.new

  server =
    Mint::LS::Server.new(in_io, out_io)

  messages.map do |item|
    out_io.clear
    in_io.clear

    in_io.print "Content-Length: #{item.bytesize}\r\n\r\n#{item}"
    in_io.rewind # Rewind in IO so the server can read it

    # Process the message
    server.read

    content = LSP::MessageParser.parse(out_io.rewind, &.itself).not_nil!

    # Prettify response
    json = JSON.parse(content)
    json.to_pretty_json
  end
end

def format_xml(xml)
  input, output, error =
    {IO::Memory.new(xml), IO::Memory.new, IO::Memory.new}

  Process.run(
    args: ["--format", "-"],
    command: "xmllint",
    clear_env: true,
    output: output,
    input: input,
    error: error,
    env: {
      "NO_COLOR" => "1",
    })

  output.rewind.gets_to_end
end
