#!/usr/bin/env ruby
# encoding: utf-8
require 'fileutils'
require 'timeout'
require 'net/https'
require 'uri'

require './eval/eval.rb'

require 'rubygems'
require 'bundler/setup'
require 'json'
require 'on_irc'
require 'future'
require 'configru'
require 'nokogiri'
require 'pry'

Configru.load do
  just 'rublets.yml'
  
  defaults do
    servers {}
    nickname 'rublets'
    comchar '!'
    default_ruby 'ruby-1.9.3-p0'
  end

  verify do
    nickname /^[A-Za-z0-9_\`\[\{}^|\]\\-]+$/
  end
end

#bot = Thread.new do
@bot = IRC.new do
  nick Configru.nickname
  ident Configru.nickname
  realname 'Ruby Safe-Eval bot.'

  Configru.servers.each_pair do |name, server_cfg|
    server name do
      address server_cfg.address
    end
  end
end

Configru.servers.each_pair do |name, server_cfg|
  @bot[name].on '001' do
    server_cfg.channels.each do |channel|
      join channel
    end
  end
end

languages = {
  'scala' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => [
      'scala',
      '-J-server', '-J-XX:+TieredCompilation', '-nocompdaemon', '-deprecation'
    ],
    :timeout              => 20,
    :extension            => 'scala',
    :output_limit         => 2,
  },
  'python' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['python'],
    :timeout              => 5,
    :extension            => 'py',
    :output_limit         => 2,
  },
  'erlang' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['escript'],
    :timeout              => 5,
    :extension            => 'erl',
    :output_limit         => 2,
    :before               => [
      '#!/usr/bin/env escript',
      '%%! -smp enable -mnesia debug verbose',
    ].join("\n") + "\n",
  },
  'javascript' => {
    :aliases              => ['js'],
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['js'],
    :timeout              => 5,
    :extension            => 'js',
    :output_limit         => 2,
  },
  'lua' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['lua'],
    :timeout              => 5,
    :extension            => 'lua',
    :output_limit         => 2,
  },
  'ocaml' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => [
      'ocaml',
      '-noprompt'
    ],
    :timeout              => 5,
    :extension            => 'ml',
    :skip_preceding_lines => 2,
    :code_from_stdin      => true,
    :output_limit         => 2,
  },
  'smalltalk' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['gst'],
    :timeout              => 5,
    :extension            => 'st',
    :output_limit         => 2,
  },
  'objective-c' => {
    :aliases              => ['obj-c'],
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['bash', 'run-obj-c.sh'],
    :binaries_must_exist  => ['gcc', 'bash'],
    :timeout              => 5,
    :extension            => 'm',
    :output_limit         => 2,
    :required_files       => {'eval/run-obj-c.sh' => 'run-obj-c.sh'},
    :before               => [
      '#import <Foundation/Foundation.h>',
    ].join("\n") + "\n",
  },
  'haskell' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['ghci', '-v0'],
    :timeout              => 5,
    :extension            => 'hs',
    :output_limit         => 2,
    :code_from_stdin      => true,
  },
  'bash' => {
    :aliases              => ['$'],
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['bash'],
    :timeout              => 5,
    :extension            => 'sh',
    :output_limit         => 2,
  },
  'zsh' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['zsh'],
    :timeout              => 5,
    :extension            => 'sh',
    :output_limit         => 2,
  },
  'perl' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['perl'],
    :timeout              => 5,
    :extension            => 'pl',
    :output_limit         => 2,
  },
  'elixir' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['elixir'],
    :timeout              => 5,
    :extension            => 'exs',
    :output_limit         => 2,
    :alter_code           => lambda { |code|
      eval_code = code.inspect
      "{r, _} = Code.eval(#{eval_code}, []); IO.puts inspect(r)"
    },
  },
  'maxima' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => [
      'maxima',
      '--very-quiet', '--disable-readline'
    ],
    :timeout              => 5,
    :extension            => 'maxima',
    :output_limit         => 2,
    :code_from_stdin      => true,
    :alter_code           => lambda { |code|
      "display2d: false$ leftjust: true$ #{code}#{";" unless (code.end_with?(';') || code.end_with?('$'))}"
    },
  },
  'go' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['bash', 'run-go.sh'],
    :binaries_must_exist  => ['gccgo', 'bash'],
    :timeout              => 5,
    :extension            => 'go',
    :output_limit         => 2,
    :required_files       => {'eval/run-go.sh' => 'run-go.sh'},
    :before               => [
      'package main',
      'import "fmt"',
    ].join("\n") + "\n",
  },
  'pascal' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['bash', 'run-pascal.sh'],
    :binaries_must_exist  => ['fpc', 'bash'],
    :timeout              => 5,
    :extension            => 'pas',
    :output_limit         => 2,
    :required_files       => {'eval/run-pascal.sh' => 'run-pascal.sh'},
    :before               => 'program RubletsEval(output);' + "\n",
  },
  'io' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['io'],
    :timeout              => 5,
    :extension            => 'io',
    :output_limit         => 2,
  },
  'forth' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['gforth'],
    :timeout              => 5,
    :extension            => 'forth',
    :output_limit         => 2,
    :after                => ' bye',
  },
  'perpetual' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => [
      'perpetual',
      '--no-prompt'
    ],
    :timeout              => 5,
    :extension            => 'perp',
    :output_limit         => 2,
    :code_from_stdin      => true,
    :skip_preceding_lines => 1,
  },
  'lisp' => {
    :aliases              => ['sbcl'],
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => [
      'sbcl',
      '--script'
    ],
    :timeout              => 5,
    :extension            => 'cl',
    :output_limit         => 2,
  },
  'c' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['bash', 'run-c.sh'],
    :binaries_must_exist  => ['gcc', 'bash'],
    :timeout              => 5,
    :extension            => 'c',
    :output_limit         => 2,
    :required_files       => {'eval/run-c.sh' => 'run-c.sh',
                              'eval/rublets-c.h' => 'stdinc.h'},
    :before               => "#include \"stdinc.h\"\n",
  },
  'c++' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['bash', 'run-cpp.sh'],
    :binaries_must_exist  => ['g++', 'bash'],
    :timeout              => 5,
    :extension            => 'cpp',
    :output_limit         => 2,
    :required_files       => {'eval/run-cpp.sh' => 'run-cpp.sh'},
    :before               => File.read('eval/rublets-cpp.h'),
  },
  'php' => {
    :path                 => File.expand_path('~/.rublets'),
    :evaluate_with        => ['php'],
    :timeout              => 5,
    :extension            => 'php',
    :output_limit         => 2,
    :alter_code           => lambda { |code|
      code = "<?php #{code}" unless code.start_with?("<?")
      code.gsub!(/^<\? /, '<?php ') if code.start_with?("<? ")
      code
    },
  },
}

def lang_from_hash_by_name(languages, name)
  return nil if name == nil
  name.downcase!
  
  return languages[name] if languages.has_key?(name)
  
  languages.each do |lang, params|
    return languages[lang] if !params[:aliases].nil? and params[:aliases].include?(name)
  end
  
  nil
end

def supported_langs_in_hash(languages)
  supported = ""
  languages.each do |lang, params|
    supported += "#{lang}"
    supported += " (aka #{params[:aliases].join(", ")})" unless params[:aliases].nil?
    supported += ", "
  end
  supported
end

@bot.on :ping do
  pong params[0]
end

@bot.on :privmsg do
  begin
    matches = params[1].match(/#{Configru.comchar}(\S+)> ?(.*)/)
    unless matches.nil?
      the_lang = lang_from_hash_by_name(languages, matches[1])
      if the_lang != nil
        future do
          sandbox = Sandbox.new(the_lang.merge({:owner => sender.nick, :code => matches[2]}))
          the_lang[:required_files].each { |file,dest| sandbox.copy file, dest } unless the_lang[:required_files].nil?
          result = sandbox.evaluate
          result.each { |line| respond line }
          sandbox.rm_home!
          next
        end
      end
    end
    
    case params[1]
    when /^!rubies$/
      # Lists all available rubies.
      rubies = Dir['./rubies/*'].map { |a| File.basename(a) }
      respond "#{sender.nick}: #{rubies.join(', ')} (You can specify 'all' to evaluate against all rubies, but this might be slowish.)"

    when /^!lang(?:s|uages)$/
      respond "You can use any of these languages: #{supported_langs_in_hash(languages)}"

    when /^!<\?(php|php=|=|) (.*)/
      respond "#{sender.nick}, this PHP syntax is deprecated.  Use !php> <?php /* Your code */ instead."
      if not $1.nil? and $1.end_with? '='
        code = "<?php echo #{$2}"
      else
        code = "<?php #{$2}"
      end
      future do
        sandbox = Sandbox.new(
          :path          => File.expand_path('~/.rublets'),
          :evaluate_with => ['php'],
          :timeout       => 5,
          :extension     => 'php',
          :owner         => sender.nick,
          :output_limit  => 2,
          :code          => code
        )
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!
      end

    # Ruby eval.
    when /^!(([\w\.\-]+)?>?|>)> (.*)/
      future do
        # Pull these out of the regex here, because the global captures get reset below.
        given_version = $2 # might be nil.
        code = $3

        #future do # We can have multiple evaluations going on at once.
        rubyversion = Configru.default_ruby

        # If a version is given (so not default), scan ./rubies/* to see if it matches.
        # If there is one (and only one) match, move along and set rubyversion to that.
        # If there's more than one, or no match, warn the user and ignore the eval.
        unless given_version.nil?
          if given_version == 'all'
            rubyversion = 'all'
          else
            rubies = Dir['./rubies/*'].map { |a| File.basename(a) }
            rubies = rubies.delete_if { |ruby| ruby.scan(given_version).empty? }
            if rubies.count > 1
              respond "#{sender.nick}: You matched multiple rubies. Be more specific. See !rubies for the full list." and next
            elsif rubies.count == 0
              next
            end
            rubyversion = rubies[0]
          end
        end

        eval_code = "result = ::Kernel.eval(#{code.inspect}, TOPLEVEL_BINDING)"
        if rubyversion == 'all'
          eval_code += "\n" + 'puts RUBY_VERSION + " #{\'(\' + RUBY_ENGINE + \')\' unless defined?(RUBY_ENGINE).nil?} => " + result.inspect'
        else
          eval_code += "\n" + 'puts "=> " + result.inspect'
        end

        sandbox = Sandbox.new(
          :path                => File.expand_path('~/.rublets'),
          :evaluate_with       => ['bash', 'run-ruby.sh', rubyversion],
          :timeout             => 5,
          :extension           => 'rb',
          :owner               => sender.nick,
          :output_limit        => 2,
          :code                => eval_code,
          :binaries_must_exist => ['ruby', 'bash'],
          )

        sandbox.copy 'rvm', '.rvm'

        # If the user wants to eval against all rubies, then copy the entire rubies directory.
        if rubyversion == 'all'
          sandbox.copy 'rubies', '.rvm/rubies/'
        else
          sandbox.mkdir(".rvm/rubies")
          sandbox.copy "rubies/#{rubyversion}", ".rvm/rubies/#{rubyversion}"
        end

        # This is a bit of a hack, but lets us set up the rvm environment and call the script.
        sandbox.copy 'eval/run-ruby.sh', 'run-ruby.sh'
        result = sandbox.evaluate
        result.each { |line| respond line }
        sandbox.rm_home!
      end
    end # end case
  rescue ThreadError
    respond "Could not create thread."
  end
end # end on :privmsg
@bot.connect
#end # end thread

#bot.join
