# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'things3_mcp'
require 'things3_mcp/http/app'

run Things3Mcp::Http::App.build
