class FsPrompt < ActiveRecord::Base
  has_many :fs_extensions
  dependent_restrict :fs_extensions
#  validate_fields self

  validates_presence_of :length, :message => 'Only 16bit, 8kHz, mono Wav files accepted'
  validates_presence_of :name, :message => 'Please supply a name for the prompt'

  before_validation_on_create :save_file

  def file=(file)
    @file = file
  end

  def save_file()
    if !@file.blank?
      filename =  File.basename(@file.original_filename)
      filename.sub(/[^\w\.\-]/,'_') 
      write_attribute :filename, filename
      directory = "public/prompts"
      FileUtils.mkdir_p directory
      path = File.join(directory, filename)
      fdata = @file.read
      File.open(path, "wb") { |f| f.write(fdata) }
      begin
        wav = Wave.new(path)
        write_attribute :length, wav.length if wav.channels == 1 and wav.bits == 16 and wav.rate == 8000
      rescue => ex
      end
    end
  end

end


# Copyright (c) 2005 Ariff Abdullah 
#        (skywizard@MyBSD.org.my) All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
#        $MyBSD$
#
# Date: Sun Feb 20 20:49:23 MYT 2005
#   OS: FreeBSD kasumi.MyBSD.org.my 5.3-STABLE i386
#

class WaveError < StandardError
end

class Wave
  def initialize(file)
    @file = file.dup()
    @fsize = File.size(@file)
    @fd = File.open(@file, 'rb')
    @fmt = @bits = @rate = @size = @channels = @length = nil
    catch :success do
      begin
        while true
          hdr = @fd.sysread(8)
          raise WaveError, 'read failed' unless hdr.size == 8
          hdr, sz = hdr.unpack('a4I')
          case hdr
            when 'RIFF'
              hdr = @fd.sysread(4)
              raise WaveError, 'read failed' unless hdr.size == 4
              hdr = hdr.unpack('a4')[0]
              raise WaveError, 'Not a WAVE' unless hdr == 'WAVE'
            when 'fmt '
              raise WaveError, 'Illegal header' if sz < 16
              hdr = @fd.sysread(16)
              raise WaveError, 'read failed' unless hdr.size == 16
              waveheader = hdr.unpack('SSIISS')
              case waveheader[0]
                when 0x0001
                  @fmt = waveheader[5]
                when 0x0006, 0x0007
                  @fmt = waveheader[0]
              else
                raise WaveError, 'Unsupported format 0x%04X' % waveheader[0]
              end
              @bits = waveheader[5]
              @rate = waveheader[2]
              @channels = waveheader[1]
              sz -= 16
              if sz > 0
                pos = @fd.sysseek(0, IO::SEEK_CUR)
                raise WaveError, 'seek failed' \
                    unless pos + sz == @fd.sysseek(sz, IO::SEEK_CUR)
              end
            when 'data'
              hs = @fd.sysseek(0, IO::SEEK_CUR)
              @size = @fsize - hs
              @length = 8.0 * @size / @rate / @channels / @bits
              throw :success
          else
            pos = @fd.sysseek(0, IO::SEEK_CUR)
            raise WaveError, 'Not a RIFF' if pos == 8
            raise WaveError, 'seek failed' \
                unless pos + sz == @fd.sysseek(sz, IO::SEEK_CUR)
          end
        end
        raise EOFError
      rescue EOFError
        raise WaveError, 'data chunk not found'
      end
    end
    raise WaveError, 'Wave header error' \
        unless @bits && @rate && @channels && @fmt && @size
    self
  end
  attr_reader :file, :channels, :bits, :rate, :size, :fmt, :length
end


