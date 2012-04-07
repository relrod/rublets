class Language
  attr_accessor :languages

  # Public: A Hash containing every language that we support (sans special
  #         cases which are in rublets.rb itself), which includes information
  #         about how to evaluate the language.
  #
  # Returns a large Hash of Hashes which explains how to run an evaluation
  #   and contains necessary metadata for doing so.
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
        :version_against      => 'frink',
        :timeout              => 6,
        :extension            => 'frink',
        :output_limit         => 2,
        :code_from_stdin      => true,
        :skip_preceding_lines => 1,
        :skip_ending_lines    => 1
      },
    }
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
    return nil if name == nil

    name.downcase!

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
    supported = []
    languages.each do |lang, params|
      lang += " (aka #{params[:aliases].join(", ")})" unless params[:aliases].nil?
      supported << lang
    end
    supported.sort.join(', ')
  end

  # Public: Give the version of a supported language.
  #
  # language        - A Hash containing information about a language.
  # version_command - A String with the default way to get the version of the
  #                   language. A literal (sans quotes) "{}" will be replaced
  #                   with the FULL PATH to the binary. Otherwise the FULL
  #                   PATH will be appended to the end of the String.
  #
  # If the language has a defined :version_against, that binary is used.
  # Otherwise, the first element of :evaluate_with is used.
  #
  # The binary to version against MUST be in $PATH or no version will return.
  #
  # The reason this uses package managers to do its works is because Rublets
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
    # Use :version_against or :binaries_must_exist[0]
    binary = if language[:version_against]
               language[:version_against]
             else
               if language[:binaries_must_exist]
                 language[:binaries_must_exist][0]
               elsif language[:evaluate_with]
                 language[:evaluate_with][0]
               else
                 nil
               end
             end
    return nil if binary == nil
    
    # Get the absolute path of the interpreter/compiler.
    path_to_binary = ''
    ENV['PATH'].split(':').each do |path|
      if File.exists? File.join(path, '/', binary)
        path_to_binary = File.join(path, '/', binary)
        break
      end
    end
    return nil if path_to_binary == ''

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
