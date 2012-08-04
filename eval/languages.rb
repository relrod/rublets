class Language

  @eval_path = File.dirname(__FILE__)

  # Public: A Hash containing every language that we support (sans special
  #         cases which are in rublets.rb itself), which includes information
  #         about how to evaluate the language.
  #
  # !!! PLEASE KEEP THIS LIST ALPHABETICAL !!!
  # !!! PLEASE KEEP THIS LIST ALPHABETICAL !!!
  # !!! PLEASE KEEP THIS LIST ALPHABETICAL !!!
  #
  # Returns a large Hash of Hashes which explains how to run an evaluation
  #   and contains necessary metadata for doing so.
  @languages = {
    'apricot' => {
      :aliases              => ['apr'],
      :evaluate_with        => ['/usr/local/rvm/bin/rvm',
        'rbx-head', 'do', 'rbx', '-X19',
        '-I/opt/rublets/programble-apricot/lib', '-rapricot'
      ],
      :timeout              => 5,
      :alter_code           => lambda { |code|
        "begin
  puts \"=> \" + Apricot::Compiler.eval(#{code.inspect}).apricot_inspect
rescue Exception => e
  puts \"\#{e.class}: \#{e.message}\"
end"
      },
      :version_lambda       => lambda {
        Dir.chdir('/opt/rublets/programble-apricot')
        `git log --format='%h - %cD' -1`
      },
      :extension            => 'rb',
    },
    'arroyo' => {
      :evaluate_with        => ['arroyo'],
      :timeout              => 5,
      :extension            => 'arr',
      :before               => 'print (',
      :after                => ')',
    },
    'bash' => {
      :aliases              => ['$'],
      :evaluate_with        => ['bash'],
      :timeout              => 5,
      :extension            => 'sh',
    },
    'befunge' => {
      :evaluate_with        => ['befrunge'],
      :timeout              => 5,
      :extension            => 'bf',
    },
    'brainfuck' => {
      :evaluate_with        => ['bf.rb'],
      :timeout              => 5,
      :aliases              => ['bf'],
      :extension            => 'b',
    },
    'c' => {
      :evaluate_with        => ['bash', 'run-c.sh'],
      :binaries_must_exist  => ['gcc', 'bash'],
      :timeout              => 5,
      :extension            => 'c',
      :required_files       => {"#{@eval_path}/run-c.sh" => 'run-c.sh',
        "#{@eval_path}/rublets-c.h" => 'stdinc.h'},
      :before               => "#include \"stdinc.h\"\n",
    },
    'c#' => {
      :aliases              => ['csharp'],
      :evaluate_with        => ['bash', 'run-cs.sh'],
      :binaries_must_exist  => ['mcs', 'bash'],
      :timeout              => 5,
      :extension            => 'cs',
      :required_files       => {"#{@eval_path}/run-cs.sh" => 'run-cs.sh'},
    },
    'c++' => {
      :evaluate_with        => ['bash', 'run-cpp.sh'],
      :binaries_must_exist  => ['g++', 'bash'],
      :timeout              => 5,
      :extension            => 'cpp',
      :required_files       => {"#{@eval_path}/run-cpp.sh" => 'run-cpp.sh'},
      :before               => File.read("#{@eval_path}/rublets-cpp.h"),
    },
    'clay' => {
      :evaluate_with        => ['clay', '-run'],
      :timeout              => 5,
      :extension            => 'clay',
    },
    'clojure' => {
      :aliases              => ['clj'],
      :evaluate_with        => ['clojure'],
      :timeout              => 5,
      :code_from_stdin      => true,
      :alter_result         => lambda { |result|
        result.gsub(/^user=> /, '')
      },
      :skip_preceding_lines => 1,
      :extension            => 'clj',
    },
    'elixir' => {
      :evaluate_with        => ['elixir'],
      :timeout              => 5,
      :extension            => 'exs',
      :alter_code           => lambda { |code|
        eval_code = code.inspect
        "{r, _} = Code.eval(#{eval_code}, []); IO.puts inspect(r)"
      },
    },
    'erlang' => {
      :evaluate_with        => ['escript'],
      :timeout              => 5,
      :extension            => 'erl',
      :before               => [
        '#!/usr/bin/env escript',
        '%%! -smp enable -mnesia debug verbose',
      ].join("\n") + "\n",
    },
    'forth' => {
      :evaluate_with        => ['gforth'],
      :timeout              => 5,
      :extension            => 'forth',
      :after                => ' bye',
    },
    'frink' => {
      :evaluate_with        => [
        'java', '-cp', '/usr/share/java/frink.jar', 'frink.parser.Frink'
      ] + (File.exists?('/etc/frink/units.txt') ? ['-u', '/etc/frink/units.txt'] : []),
      :version_against      => '/usr/share/java/frink.jar',
      :timeout              => 6,
      :extension            => 'frink',
      :code_from_stdin      => true,
      :skip_preceding_lines => 1,
      :skip_ending_lines    => 1,
    },
    'go' => {
      :evaluate_with        => ['bash', 'run-go.sh'],
      :binaries_must_exist  => ['gccgo', 'bash'],
      :timeout              => 5,
      :extension            => 'go',
      :required_files       => {"#{@eval_path}/run-go.sh" => 'run-go.sh'},
      :before               => [
        'package main',
        'import "fmt"',
      ].join("\n") + "\n",
    },
    'golfscript' => {
      :evaluate_with        => ['golfscript'],
      :binaries_must_exist  => ['golfscript'],
      :timeout              => 5,
      :extension            => 'gs',
    },
    'haskell' => {
      :evaluate_with        => ['ghci', '-v0'],
      :timeout              => 5,
      :extension            => 'hs',
      :code_from_stdin      => true,
    },
    'io' => {
      :evaluate_with        => ['io'],
      :timeout              => 5,
      :extension            => 'io',
    },
    'j' => {
      :evaluate_with        => ['j-language'],
      :timeout              => 5,
      :extension            => 'j',
      :code_from_stdin      => true,
      :skip_ending_lines    => 1,
      :alter_result         => lambda { |result| result.lstrip }
    },
    'java' => {
      :evaluate_with        => ['bash', 'run-java.sh'],
      :binaries_must_exist  => ['javac', 'java', 'bash'],
      :timeout              => 5,
      :extension            => 'java',
      :required_files       => {"#{@eval_path}/run-java.sh" => 'run-java.sh'},
      :script_filename      => 'Rublets.java',
      :alter_code           => lambda { |code|
        return code if code.include? 'class Rublets'
        return "public class Rublets { #{code} }"
      }
    },
    'javascript' => {
      :aliases              => ['js'],
      :evaluate_with        => ['js', '-i'],
      :timeout              => 5,
      :extension            => 'js',
      :code_from_stdin      => true,
      :skip_preceding_lines => 1,
      :skip_ending_lines    => 1,
    },
    'lisp' => {
      :aliases              => ['sbcl'],
      :evaluate_with        => [
        'sbcl',
        '--script'
      ],
      :timeout              => 5,
      :extension            => 'cl',
    },
    'lua' => {
      :evaluate_with        => ['lua', '-i'],
      :timeout              => 5,
      :extension            => 'lua',
      :skip_preceding_lines => 2,
      :skip_ending_lines    => 1,
      :code_from_stdin      => true,
    },
    'maxima' => {
      :evaluate_with        => [
        'maxima',
        '--very-quiet', '--disable-readline'
      ],
      :timeout              => 5,
      :extension            => 'maxima',
      :code_from_stdin      => true,
      :alter_code           => lambda { |code|
        "display2d: false$ leftjust: true$ #{code}#{";" unless (code.end_with?(';') || code.end_with?('$'))}"
      },
    },
     'mruby' => {
      :evaluate_with        => ['mruby'],
      :timeout              => 5,
      :extension            => 'rb',
      # mruby doesn't seem to be able to TOPLEVEL_BIND. -CodeBlock.
      #      :alter_code           => lambda { |code|
      #        code = "result = ::Kernel.eval(#{code.inspect}, TOPLEVEL_BINDING)"
      #        code += "\n" + 'puts "=> " + result.inspect'
      #        code
      #      },
    },
    'objective-c' => {
      :aliases              => ['obj-c'],
      :evaluate_with        => ['bash', 'run-obj-c.sh'],
      :binaries_must_exist  => ['gcc', 'bash'],
      :timeout              => 5,
      :extension            => 'm',
      :required_files       => {"#{@eval_path}/run-obj-c.sh" => 'run-obj-c.sh'},
      :before               => [
        '#import <Foundation/Foundation.h>',
      ].join("\n") + "\n",
    },
    'ocaml' => {
      :evaluate_with        => ['bash', 'run-ocaml.sh'],
      :timeout              => 5,
      :extension            => 'ml',
      :required_files       => {"#{@eval_path}/run-ocaml.sh" => 'run-ocaml.sh'},
      :script_filename      => 'evaluation.ml',
    },
    'pascal' => {
      :evaluate_with        => ['bash', 'run-pascal.sh'],
      :binaries_must_exist  => ['fpc', 'bash'],
      :timeout              => 5,
      :extension            => 'pas',
      :required_files       => {"#{@eval_path}/run-pascal.sh" => 'run-pascal.sh'},
      :before               => 'program RubletsEval(output);' + "\n",
    },
    'perl' => {
      :aliases              => ['perl5'],
      :evaluate_with        => ['perl'],
      :timeout              => 5,
      :extension            => 'pl',
    },
    'perl6' => {
      :aliases              => ['rakudo'],
      :evaluate_with        => ['perl6'],
      :timeout              => 6,
      :extension            => 'pl',
    },
    'perpetual' => {
      :evaluate_with        => [
        'perpetual',
        '--no-prompt'
      ],
      :timeout              => 5,
      :extension            => 'perp',
      :code_from_stdin      => true,
      :skip_preceding_lines => 1,
    },
    'php' => {
      :evaluate_with        => ['php'],
      :timeout              => 5,
      :extension            => 'php',
      :alter_code           => lambda { |code|
        code = "<?php #{code}" unless code.start_with?("<?")
        code.gsub!(/^<\? /, '<?php ') if code.start_with?("<? ")
        code
      },
    },
    'python' => {
      :evaluate_with        => ['python'],
      :timeout              => 5,
      :extension            => 'py',
    },
    'python3' => {
      :evaluate_with        => ['python3'],
      :timeout              => 5,
      :extension            => 'py',
      :output_limit         => 2,
    },
    'scala' => {
      :evaluate_with        => [
        'scala',
        '-J-server', '-J-XX:+TieredCompilation', '-nocompdaemon', '-deprecation'
      ],
      :timeout              => 7,
      :extension            => 'scala',
      :code_from_stdin      => true,
      :skip_preceding_lines => 5,
      :skip_ending_lines    => 2,
    },
    'smalltalk' => {
      :evaluate_with        => ['gst'],
      :timeout              => 5,
      :extension            => 'st',
    },
    'sqlite' => {
      :evaluate_with        => ['sqlite3', Time.now.to_f.to_s],
      :timeout              => 5,
      :aliases              => ['sqlite3'],
      :extension            => 'sqlite',
      :code_from_stdin      => true,
    },
    'zsh' => {
      :evaluate_with        => ['zsh'],
      :timeout              => 5,
      :extension            => 'sh',
    },
  }

  # Be able to modify the map of languages dynamically.
  # This lets us add special cases to the map.
  class << self
    attr_accessor :languages
  end
  
  # Public: Finds a Hash for a given languages that we can evaluate.
  #
  # lang_name - A String containing a language name that a Hash should be
  #             returned for.
  #
  # Returns a Hash containing information about how we should execute a language
  #   or nil if the language is not supported.
  #
  def self.by_name(lang_name)
    return nil if lang_name == nil

    lang_name.downcase!

    return languages[lang_name] if languages.has_key?(lang_name)

    languages.each do |lang, params|
      return languages[lang] if !params[:aliases].nil? and params[:aliases].include?(lang_name)
    end
    
    nil
  end

  # Public: A method to return, in human-readable form, a String that lists all
  #         the languages that we can evaluate.
  #
  # Returns a String containing all of the languages that we can evaluate.
  def self.list_all
    languages.keys.sort.join(', ')
  end

  # Public: Give the version of a supported language.
  #
  # language        - A Hash containing information about a language.
  # version_command - A String with the default way to get the version of the
  #                   language. A literal (sans quotes) "{}" will be replaced
  #                   with the FULL PATH to the binary. Otherwise the FULL
  #                   PATH will be appended to the end of the String.
  #
  # If the language has a defined :version_against, that path is used.
  # Otherwise, the first element of :evaluate_with is used.
  #
  # The binary to version against MUST be in $PATH or no version will return.
  #
  # The reason this uses package managers to do its work is because Rublets
  # supports (and likes supporting) newer, in-development languages, and
  # those often don't have stable releases, just git commits. Rather than
  # the maintainer of the language requiring a .git directory, and making
  # git a build requirement, so that the compiler compiles in the git hash
  # for `the_language --version`, we just assume that the *packager* of the
  # language will put the git commit (or at least the date that git was pulled
  # from) in the version of the package. This is required per e.g. Fedora
  # snapshot packages as seen here:
  # http://fedoraproject.org/wiki/Packaging:NamingGuidelines#Snapshot_packages
  #
  # This takes burden off of the developer, and still lets users be able to
  # quickly and easily find out how far out of date the version we're evaluating
  # against is. This is the reason that we rely on the package manager to show
  # what version we have.
  #
  # Examples
  #
  #   # Fedora, RHEL, CentOS, Scientific Linux, etc.
  #   Language.version(Language.by_name('php'), 'rpm -qf')
  #   # => php-cli-5.4.0-5.fc18.x86_64
  #
  #   # Debian, Ubuntu, etc.
  #   Language.version(Language.by_name('perl'),
  #     "dpkg-query -W -f '${Package}-${Version}\n' $(dpkg -S {} | awk -F: '{print $1}')"
  #
  # Returns the version of the language as a String, or nil if the language is
  #   not in $PATH.
  def self.version(language, version_command)
    if language[:version_lambda]
      return language[:version_lambda].call
    end

    # Use :version_against or :binaries_must_exist[0]
    binary = if language[:version_against]
               language[:version_against]
             elsif language[:binaries_must_exist]
               language[:binaries_must_exist][0]
             elsif language[:evaluate_with]
               language[:evaluate_with][0]
             end
    return nil unless binary
    
    # Get the absolute path of the interpreter/compiler.
    if language[:version_against]
      path_to_binary = language[:version_against]
    else
      path_to_binary = ''
      ENV['PATH'].split(':').each do |path|
        if File.exists? File.join(path, '/', binary)
          path_to_binary = File.join(path, '/', binary)
          break
        end
      end
      return nil if path_to_binary.empty?
    end

    # Swap out all '{}' with the actual path, if we need to.
    # If '{}' doesn't appear, just throw path_to_binary on the end.
    if version_command.include? '{}'
      version_command.gsub!('{}', path_to_binary)
    else
      version_command = "#{version_command} #{path_to_binary}"
    end

    return `#{version_command}`.strip
  end
end
