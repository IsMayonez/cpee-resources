#!/usr/bin/ruby
#
# This file is part of CPEE-RESOURCES.
#
# CPEE-RESOURCES is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# CPEE-RESOURCES is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with CPEE-RESOURCES (file LICENSE in the main directory). If not, see
# <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'riddl/server'

module CPEE
  module Resources

    SERVER = File.expand_path(File.join(__dir__,'implementation.xml'))

    class DoExists < Riddl::Implementation #{{{
      def response
        data = @a[1]
        dir = File.join(data,@a[0],Riddl::Protocols::Utils::escape(@r[-1]))
        if Dir.exist?(dir)
          return Riddl::Parameter::Complex.new('exists','text/xml') do
            doc = XML::Smart::string('<resource/>')
            doc.root.add('schema','schema.rng') if File.exist?(File.join(dir,'schema.rng'))
            doc.root.add('symbol','symbol.svg') if File.exist?(File.join(dir,'symbol.svg'))
            doc.root.add('properties','properties.json') if File.exist?(File.join(dir,'properties.json'))
            doc.to_s
          end
        else
          @status = 404
          Riddl::Parameter::Complex.new('exists','text/plain','Existence really is an imperfect tense that never becomes a present. (Friedrich Nietzsche)')
        end
      end
    end #}}}
    class DoModExists < Riddl::Implementation #{{{
      def response
        data = @a[1]
        dir = File.join(data,'modifiers',Riddl::Protocols::Utils::escape(@r[-2]),Riddl::Protocols::Utils::escape(@r[-1]))
        if Dir.exist?(dir)
          Riddl::Parameter::Complex.new('exists','text/xml') do
            doc = XML::Smart::string('<resource/>')
            doc.root.add('patch','patch.xml') if File.exist?(File.join(dir,'patch.xml'))
            doc.root.add('unpatch','unpatch.xml') if File.exist?(File.join(dir,'unpatch.xml'))
            doc.root.add('condition','condition.json') if File.exist?(File.join(dir,'condition.json'))
            doc.root.add('ui','ui.rng') if File.exist?(File.join(dir,'ui.rng'))
            doc.to_s
          end
        else
          @status = 404
          Riddl::Parameter::Complex.new('exists','text/plain','Existence really is an imperfect tense that never becomes a present. (Friedrich Nietzsche)')
        end
      end
    end #}}}
    class DoFile < Riddl::Implementation #{{{
      def response
        data = @a[1]
        file = File.join(data,@a[0],*(@r[@a[2]].map{|e| Riddl::Protocols::Utils::escape(e)}))
        if File.exist?(file)
          Riddl::Parameter::Complex.new(@a[3],@a[4],File.read(file))
        else
          @status = 404
          Riddl::Parameter::Complex.new('exists','text/plain','Existence really is an imperfect tense that never becomes a present. (Friedrich Nietzsche)')
        end
      end
    end #}}}
    class DoList < Riddl::Implementation #{{{
      def response
        data = @a[1]
        @a[2] ||= 0...0
        dir = File.join(data,@a[0],*(@r[@a[2]].map{|e| Riddl::Protocols::Utils::escape(e)}))
        return Riddl::Parameter::Complex.new('list','text/xml') do
          doc = XML::Smart::string('<resources/>')
          Dir.glob(File.join(dir,'*')).sort.each do |f|
           doc.root.add('resource',File.basename(f))
          end
          doc.to_s
        end
      end
    end #}}}
    class DoCreate < Riddl::Implementation #{{{
      def response
        data = @a[1]
        dir = File.join(data,'endpoints',Riddl::Protocols::Utils::escape(@r[-1]))
        if Dir.exist?(dir)
          @status = 409
          return Riddl::Parameter::Complex.new('error','text/plain','Endpoint already exists.')
        end
        Dir.mkdir(dir)
        File.symlink(File.join(data,'symbols','timeout.svg'),  File.join(dir,'symbol.svg'))
        File.symlink(File.join(data,'schemas','timeout.rng'),  File.join(dir,'schema.rng'))
        @status = 201
        Riddl::Parameter::Complex.new('created','text/xml','<resource/>')
      end
    end #}}}
    class DoUpdateSymlink < Riddl::Implementation #{{{
      def response
        data = @a[0]
        # @a[1] is the subfolder: 'symbols' or 'schemas'
        # @a[2] is the link filename: 'symbol.svg' or 'schema.rng'
        endpoint_dir = File.join(data,'endpoints',Riddl::Protocols::Utils::escape(@r[-2]))
        payload = @p.find { |p| p.name == 'data' } || @p[0]
        if payload.nil?
          @status = 400
          return Riddl::Parameter::Complex.new('error','text/plain','Missing "data" parameter.')
        end
        value = payload.value
        value = value.read if value.respond_to?(:read)
        target_name = value.strip
        target_file = File.join(data,@a[1],target_name)
        if !File.exist?(target_file)
          @status = 404
          return Riddl::Parameter::Complex.new('error','text/plain',"Target #{target_name} not found in #{@a[1]}.")
        end
        link_path = File.join(endpoint_dir,@a[2])
        File.delete(link_path) if File.exist?(link_path) || File.symlink?(link_path)
        File.symlink(target_file, link_path)
        Riddl::Parameter::Complex.new('updated','text/plain','OK')
      end
    end #}}}
    class DoDelete < Riddl::Implementation #{{{
      def response
        data = @a[1]
        dir = File.join(data,@a[0],Riddl::Protocols::Utils::escape(@r[-1]))
        unless Dir.exist?(dir)
          @status = 404
          return Riddl::Parameter::Complex.new('error','text/plain','Existence really is an imperfect tense that never becomes a present. (Friedrich Nietzsche)')
        end
        Dir.entries(dir).each do |f|
          next if f == '.' || f == '..'
          File.delete(File.join(dir,f))
        end
        Dir.rmdir(dir)
        Riddl::Parameter::Complex.new('deleted','text/plain','OK')
      end
    end #}}}
    class DoDeleteFile < Riddl::Implementation #{{{
      def response
        data = @a[0]
        file = File.join(data,@a[1],Riddl::Protocols::Utils::escape(@r[-1]))
        unless File.exist?(file) || File.symlink?(file)
          @status = 404
          return Riddl::Parameter::Complex.new('error','text/plain','Existence really is an imperfect tense that never becomes a present. (Friedrich Nietzsche)')
        end
        File.delete(file)
        Riddl::Parameter::Complex.new('deleted','text/plain','OK')
      end
    end #}}}
    class DoWriteFile < Riddl::Implementation #{{{
      def response
        data = @a[1]
        file = File.join(data,@a[0],*(@r[@a[2]].map{|e| Riddl::Protocols::Utils::escape(e)}))
        payload = @p.find { |p| p.name == 'data' } || @p[0]
        if payload.nil?
          @status = 400
          return Riddl::Parameter::Complex.new('error','text/plain','Missing "data" parameter.')
        end
        content = payload.value
        content = content.read if content.respond_to?(:read)
        File.write(file, content)
        Riddl::Parameter::Complex.new('updated','text/plain','OK')
      end
    end #}}}
    class DoCreateFile < Riddl::Implementation #{{{
      def response
        data = @a[0]
        file = File.join(data, @a[1], Riddl::Protocols::Utils::escape(@r[-1]))
        if File.exist?(file)
          @status = 409
          return Riddl::Parameter::Complex.new('error','text/plain','File already exists.')
        end
        payload = @p.find { |p| p.name == 'data' } || @p[0]
        if payload.nil?
          @status = 400
          return Riddl::Parameter::Complex.new('error','text/plain','Missing "data" parameter.')
        end
        content = payload.value
        content = content.read if content.respond_to?(:read)
        File.write(file, content)
        @status = 201
        Riddl::Parameter::Complex.new('created','text/xml','<created/>')
      end
    end #}}}
    class DoUpdateFile < Riddl::Implementation #{{{
      def response
        data = @a[0]
        file = File.join(data, @a[1], Riddl::Protocols::Utils::escape(@r[-1]))
        if !File.exist?(file)
          @status = 404
          return Riddl::Parameter::Complex.new('error','text/plain','Existence really is an imperfect tense that never becomes a present. (Friedrich Nietzsche)')
        end
        payload = @p.find { |p| p.name == 'data' } || @p[0]
        if payload.nil?
          @status = 400
          return Riddl::Parameter::Complex.new('error','text/plain','Missing "data" parameter.')
        end
        content = payload.value
        content = content.read if content.respond_to?(:read)
        File.write(file, content)
        Riddl::Parameter::Complex.new('updated','text/plain','OK')
      end
    end #}}}

    def self::implementation(opts)
      opts[:data_dir]           ||= File.expand_path(File.join(__dir__,'data'))

      Proc.new do
        @env['PATH_INFO'] = @env['REQUEST_URI'].split('?',2).first if @env&.key?('REQUEST_URI')
        on resource do
          on resource 'modifiers' do
            run DoList, 'modifiers', opts[:data_dir] if get
            on resource do
              run DoList, 'modifiers', opts[:data_dir], (-1..-1) if get
              on resource do
                run DoModExists, 'modifiers', opts[:data_dir] if get
                on resource 'patch.xml' do
                  run DoFile, 'modifiers', opts[:data_dir], (-3..-1), 'testset', 'text/xml' if get
                end
                on resource 'unpatch.xml' do
                  run DoFile, 'modifiers', opts[:data_dir], (-3..-1), 'testset', 'text/xml' if get
                end
                on resource 'condition.json' do
                  run DoFile, 'modifiers', opts[:data_dir], (-3..-1), 'json', 'application/json' if get
                end
                on resource 'ui.rng' do
                  run DoFile, 'modifiers', opts[:data_dir], (-3..-1), 'rng', 'text/xml' if get
                end
              end
            end
          end
          on resource 'endpoints' do
            run DoList, 'endpoints', opts[:data_dir] if get
            on resource do
              run DoExists,  'endpoints', opts[:data_dir] if get
              run DoCreate,  'endpoints', opts[:data_dir] if post
              run DoDelete,  'endpoints', opts[:data_dir] if delete
              on resource 'symbol.svg' do
                run DoFile,          'endpoints', opts[:data_dir], (-2..-1), 'svg', 'image/svg+xml' if get
                run DoUpdateSymlink, opts[:data_dir], 'symbols', 'symbol.svg'                       if put
              end
              on resource 'schema.rng' do
                run DoFile,          'endpoints', opts[:data_dir], (-2..-1), 'rng', 'text/xml' if get
                run DoUpdateSymlink, opts[:data_dir], 'schemas', 'schema.rng'                   if put
              end
              on resource 'properties.json' do
                run DoFile,      'endpoints', opts[:data_dir], (-2..-1), 'json', 'application/json' if get
                run DoWriteFile, 'endpoints', opts[:data_dir], (-2..-1)                             if put
              end
            end
          end
          on resource 'symbols' do
            run DoList, 'symbols', opts[:data_dir] if get
            on resource do
              run DoFile,       'symbols', opts[:data_dir], (-1..-1), 'svg', 'image/svg+xml' if get
              run DoCreateFile, opts[:data_dir], 'symbols'                                   if post
              run DoUpdateFile, opts[:data_dir], 'symbols'                                   if put
              run DoDeleteFile, opts[:data_dir], 'symbols'                                   if delete
            end
          end
          on resource 'schemas' do
            run DoList, 'schemas', opts[:data_dir] if get
            on resource do
              run DoFile,       'schemas', opts[:data_dir], (-1..-1), 'rng', 'text/xml' if get
              run DoCreateFile, opts[:data_dir], 'schemas'                               if post
              run DoUpdateFile, opts[:data_dir], 'schemas'                               if put
              run DoDeleteFile, opts[:data_dir], 'schemas'                               if delete
            end
          end
        end
      end
    end
  end
end
