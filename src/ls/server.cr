module Mint
  module LS
    class Server < LSP::Server
      @methods = {
        # Lifecycle methods
        "initialize" => Initialize,
        "shutdown"   => Shutdown,
        "exit"       => Exit,

        # Text document related methods
        "textDocument/completion"          => CompletionRequest,
        "textDocument/willSaveWaitUntil"   => WillSaveWaitUntil,
        "textDocument/semanticTokens/full" => SemanticTokens,
        "textDocument/foldingRange"        => FoldingRange,
        "textDocument/formatting"          => Formatting,
        "textDocument/codeAction"          => CodeAction,
        "textDocument/definition"          => Definition,
        "textDocument/didChange"           => DidChange,
        "textDocument/didOpen"             => DidOpen,
        "textDocument/hover"               => Hover,

        # Workspace related methods
        "workspace/applyEdit" => ApplyEdit,

        # Mint specific methods
        "mint/sandboxCompile" => SandboxCompile,
      }

      property params : LSP::InitializeParams? = nil

      @@workspaces = {} of String => FileWorkspace

      # Logs the given stack.
      def debug_stack(stack : Array(Ast::Node))
        stack.each_with_index do |item, index|
          class_name = item.class

          if index.zero?
            log(class_name.to_s)
          else
            log("#{" " * (index - 1)} ↳ #{class_name}")
          end
        end
      end

      # Returns the nodes at the given cursor (position)
      def nodes_at_cursor(path : String, position : LSP::Position) : Array(Ast::Node)
        nodes_at_path(path)
          .select!(&.location.contains?(position.line + 1, position.character))
      end

      def nodes_at_cursor(params : LSP::TextDocumentPositionParams) : Array(Ast::Node)
        nodes_at_cursor(params.path, params.position)
      end

      def nodes_at_cursor(params : LSP::CodeActionParams) : Array(Ast::Node)
        nodes_at_cursor(params.text_document.path, params.range.start)
      end

      def workspace(path : String)
        Workspace[path]
      end

      def workspace(uri : URI)
        Workspace[uri.path.to_s]
      end

      def nodes_at_path(path : String)
        Workspace[path]
          .ast
          .nodes
          .select(&.file.path.==(path))
      end

      # TODO: Rename to workspace
      def ws(path : String) : FileWorkspace
        base =
          File.find_in_ancestors(path, "mint.json").to_s

        # TODO: Turn on `watch` when watcher supports direct update on
        #       initialize.
        @@workspaces[base] ||=
          FileWorkspace.new(
            include_tests: true,
            check: Check::Unreachable,
            listener: nil,
            format: false,
            watch: false,
            path: base)
      end
    end
  end
end
