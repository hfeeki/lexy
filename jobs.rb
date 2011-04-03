#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require 'dm-core'
require 'dm-sqlite-adapter'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-types'
require "active_support"
require "erubis"
require "pathname"
require 'tempfile'
require "stalker"

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/my.db")

require_relative "models/lexy"

include Stalker

job 'container.configure' do |args|
  args.symbolize_keys!
  container = Container.first(:name => args[:name])
  container.configure
end

job 'container.clean' do |args|
  args.symbolize_keys!
  Container.first(:name => args[:name]).clean
end

job 'container.destroy' do |args|
  args.symbolize_keys!
  Container.first(:name => args[:name]).destroy
end

job 'container.restart' do |args|
  args.symbolize_keys!
  container = Container.first(:name => args[:name])
  container.stop
  container.configure
  container.start
end

job 'container.start' do |args|
  args.symbolize_keys!
  container = Container.first(:name => args[:name])
  container.configure
  container.start
end

job 'container.stop' do |args|
  args.symbolize_keys!
  Container.first(:name => args[:name]).stop
end

job 'container.ssh' do |args|
  args.symbolize_keys!
  command = args[:command]
  container = Container.first(:name => args[:name])
  Tempfile.open(container.name, container.path) do |f|
    f.write(container.private_key)
    f.close
    data = `ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeychecking=no -o CheckHostIP=no -o LogLevel=ERROR -i #{f.path} #{container.ssh_to} '#{command}'`
    f.unlink
    p data
  end
end

job 'containers.refresh' do |args|
  Container.all.each do |c|
    c.refresh
  end
end

# EOF
