# Things3 MCP Server

A Model Context Protocol (MCP) server for interacting with Things 3 on macOS, built with Ruby using the fast-mcp gem.

This implementation is based on [things3-mcp-ruby](https://github.com/mattsafaii/things3-mcp-ruby) by mattsafaii.

## Features

This MCP server provides tools to interact with Things 3:

- **add_task** - Add new tasks with natural language date parsing
- **get_tasks** - Retrieve tasks from various lists with filtering options
- **update_task** - Update existing tasks
- **complete_task** - Mark tasks as completed
- **delete_task** - Delete tasks
- **move_task** - Move tasks between projects and areas
- **filter_tasks** - Advanced filtering with multiple criteria
- **bulk_create** - Create multiple tasks at once
- **weekly_review** - Generate weekly productivity reviews
- **productivity_stats** - Analyze productivity patterns

## Installation

1. Clone this repository
2. Install dependencies:
   ```bash
   bundle install
   ```

## Usage

Run the MCP server:

```bash
./things3_mcp_server.rb
```

Or with Ruby:

```bash
ruby things3_mcp_server.rb
```

## Configuration

The server uses the MCP protocol over stdio. Configure your MCP client to connect to this server.

## Requirements

- macOS with Things 3 installed
- Ruby 3.4.4 or higher
- Bundler

## Development

This server is built using:
- fast-mcp gem for MCP protocol handling
- AppleScript for Things 3 integration
- Chronic gem for natural language date parsing

## License

MIT