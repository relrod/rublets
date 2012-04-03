class Language
  attr_accessor :languages
  def self.languages
    {
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
      'arroyo' => {
        :path                 => File.expand_path('~/.rublets'),
        :evaluate_with        => ['arroyo'],
        :timeout              => 5,
        :extension            => 'arr',
        :output_limit         => 2,
      },
      'clay' => {
        :path                 => File.expand_path('~/.rublets'),
        :evaluate_with        => ['clay', '-run'],
        :timeout              => 5,
        :extension            => 'clay',
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
        :aliases              => ['perl5'],
        :path                 => File.expand_path('~/.rublets'),
        :evaluate_with        => ['perl'],
        :timeout              => 5,
        :extension            => 'pl',
        :output_limit         => 2,
      },
      'perl6' => {
        :aliases              => ['rakudo'],
        :path                 => File.expand_path('~/.rublets'),
        :evaluate_with        => ['perl6'],
        :timeout              => 6,
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
      'c#' => {
        :aliases              => ['csharp'],
        :path                 => File.expand_path('~/.rublets'),
        :evaluate_with        => ['bash', 'run-cs.sh'],
        :binaries_must_exist  => ['mcs', 'bash'],
        :timeout              => 5,
        :extension            => 'cs',
        :output_limit         => 2,
        :required_files       => {'eval/run-cs.sh' => 'run-cs.sh'},
      },
      'java' => {
        :path                 => File.expand_path('~/.rublets'),
        :evaluate_with        => ['bash', 'run-java.sh'],
        :binaries_must_exist  => ['javac', 'java', 'bash'],
        :timeout              => 5,
        :extension            => 'java',
        :output_limit         => 2,
        :required_files       => {'eval/run-java.sh' => 'run-java.sh'},
        :script_filename      => 'Rublets.java'
      },
      'frink' => {
        :path                 => File.expand_path('~/.rublets'),
        :evaluate_with        => [
          'java', '-cp', '/usr/share/java/frink.jar', 'frink.parser.Frink'
        ] + (File.exists?('/etc/frink/units.txt') ? ['-u', '/etc/frink/units.txt'] : []),
        :timeout              => 6,
        :extension            => 'frink',
        :output_limit         => 2,
        :code_from_stdin      => true,
        :skip_preceding_lines => 1,
        :skip_ending_lines    => 1
      },
    }
  end
  
  def self.by_name(lang_name)
    return nil if name == nil

    name.downcase!

    return languages[lang_name] if languages.has_key?(lang_name)

    languages.each do |lang, params|
      return languages[lang] if !params[:aliases].nil? and params[:aliases].include?(lang_name)
    end
    
    nil
  end

  def self.list_all
    supported = []
    languages.each do |lang, params|
      lang += " (aka #{params[:aliases].join(", ")})" unless params[:aliases].nil?
      supported << lang
    end
    supported.sort.join(', ')
  end
end
