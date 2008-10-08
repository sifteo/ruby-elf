# Copyright 2007, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this generator; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

require 'elf'

class Elf::TestUnit < Test::Unit::TestCase
  TestDir = Pathname.new(__FILE__).dirname + "binaries"

  def filename
    self.class::Filename
  end

  def setup
    assert(File.exist?( TestDir + filename ),
           "File #{filename} not found in testsuite data directory")

    @elf = Elf::File.new( TestDir + filename )
  end

  def teardown
    @elf.close
  end

  # Test for ELF file version.
  #
  # We assume that all the ELF files we test are ELF version 1 files,
  # since there is no other version for now.
  ExpectedVersion = 1

  def test_version
    if self.class.const_defined? "ExpectedVersion"
      assert_equal(ExpectedVersion, elf.version,
                   "Unexpected ELF version")
    end
  end

  # Do a generalised test for presence of given sections
  #
  # Subclasses can fill the ExpectedSections array with the sections
  # they expect to be present in their testfile.
  ExpectedSections = []

  def test_sections_presence
    self.class::ExpectedSections.each do |section|
      assert(@elf.has_section?(section),
             "Section #{section} missing from the file")

      # Now that we know the section is present, try accessing it to
      # ensure it's available for test.
      assert_not_nil(@elf[section])
    end
  end

  # Do a generalised test for section types
  #
  # Subclasses can fill the ExpectedSectionTypes hash with section
  # names as index, and section type as value.
  ExpectedSectionTypes = {}

  def test_section_types
    self.class::ExpectedSectionTypes.each_pair do |section, type_id|
      assert_equal(type_id, @elf[section].type,
                   "Section type for #{section} differs from expectations")
    end
  end

  # Do a generalised test for section classes
  #
  # Subclasses can fill the ExpectedSectionClasses hash with section
  # names as indexes, and section class as values.
  ExpectedSectionClasses = {}
  
  def test_section_classes
    self.class::ExpectedSectionClasses.each_pair do |section, klass|
      assert_instance_of(klass, @elf[section],
                         "Object for #{section} of different class than expected")
    end
  end

  # Do a generalised test for section type classes
  #
  # Subclasses can fill the ExpectedSectionTypeClasses hash with
  # section names as indexes, and section type classes as values.
  #
  # This is useful to ensure that not only section types but also
  # section type classes (for unknown types) are detected properly
  ExpectedSectionTypeClasses = {}
  
  def test_section_type_classes
    self.class::ExpectedSectionTypeClasses.each_pair do |section, klass|
      assert_instance_of(klass, @elf[section].type,
                         "Type for #{section} of different class than expected")
    end
  end

  # Do a generalised test for section type IDs
  #
  # Subclasses can fill the ExpectedSectionTypeIDs hash with section
  # names as indexes and section type IDs as values.
  ExpectedSectionTypeIDs = {}

  def test_section_type_ids
    self.class::ExpectedSectionTypeIDs.each_pair do |section, type_id|
      assert_equal(type_id, @elf[section].type.to_i,
                   "Type for #{section} of different ID than expected")
    end
  end
end

module ElfTests
  OS_Arches = [
               "linux_x86",
               "linux_amd64",
               "linux_sparc",
               "linux_arm",
               "bare_h8300",
               "solaris_x86_gcc",
               "solaris_x86_suncc"
              ]
  def setup
    @elfs = {}

    # Check for presence of all the executables for the arches to test.
    # Make sure to check all the operating systems too.
    # Also open the ELF files for testing
    OS_Arches.each do |os_arch|
      basefilename = self.class::TestBaseFilename

      case os_arch

      # We obviously cannot test dynamic executables for bare hardware
      # targets
      when /^bare_/
        next if basefilename == "dynamic_executable"
        basefilename = "static_executable.o" if basefilename == "dynamic_executable.o"
        
      # For some reasons building static executables on OpenSolaris
      # does not look possible (misisng libc archive), thus just use
      # executable for the filename.
      when /^solaris_/
        case basefilename
        when "static_executable": next
        when "dynamic_executable": basefilename = "executable"
        when "dynamic_executable.o": basefilename = "executable.o"
        end
      end

      filename = "#{os_arch}_#{basefilename}"
      assert(File.exists?( Elf::TestUnit::TestDir + filename ),
             "Missing test file #{filename}")
      @elfs["#{os_arch}"] = Elf::File.open(Elf::TestUnit::TestDir + filename)
    end
  end
  
  def teardown
    @elfs.each_pair do |name, elf|
      elf.close
    end
  end

  # We assume that all the ELF files we test are ELF 1 files.
  def test_version
    @elfs.each_pair do |name, elf|
      assert_equal(1, elf.version,
                   "ELF version for #{elf.path} differs from expected version")
    end
  end

  def test_type
    @elfs.each_pair do |name, elf|
      assert_equal(self.class::TestElfType, elf.type)
    end
  end
  
  def test_elfclass
    @elfs.each_pair do |name, elf|
      expectedclass = case name
                      when /.*_x86/, /.*_arm/, /linux_sparc/, /.*_h8300/
                        Elf::Class::Elf32
                      when /.*_amd64/
                        Elf::Class::Elf64
                      end

      assert_equal(expectedclass, elf.elf_class,
             "ELF class for #{elf.path} differs from expected class")
    end
  end

  def test_dataencoding
    @elfs.each_pair do |name, elf|
      expectedencoding = case name
                         when /.*_x86/, /.*_amd64/, /.*_arm/
                           Elf::DataEncoding::Lsb
                         when /.*_sparc/, /.*_h8300/
                           Elf::DataEncoding::Msb
                         end

      assert_equal(expectedencoding, elf.data_encoding,
                   "ELF encoding for #{elf.path} differs from expected encoding")
    end
  end

  def test_abi
    @elfs.each_pair do |name, elf|
      expectedabi = case name
                    when /linux_arm/
                      Elf::OsAbi::ARM
                    when /linux_.*/, /bare_.*/, /solaris_.*/
                      Elf::OsAbi::SysV
                    end
      expectedabiversion = case name
                           when /linux_.*/, /bare_.*/, /solaris_.*/
                             0
                           end

      assert_equal(expectedabi, elf.abi,
                   "ELF ABI for #{elf.path} differs from expected ABI")
      assert_equal(expectedabiversion, elf.abi_version,
                   "ELF ABI version for #{elf.path} differs from expected ABI version")
    end
  end

  def test_machine
    @elfs.each_pair do |name, elf|
      expectedmachine = case name
                        when /.*_x86/
                          Elf::Machine::I386
                        when /.*_amd64/
                          Elf::Machine::X8664
                        when /.*_arm/
                          Elf::Machine::ARM
                        when /.*_sparc/
                          case elf.type
                          when Elf::File::Type::Rel then Elf::Machine::Sparc
                          when Elf::File::Type::Exec then Elf::Machine::Sparc32Plus
                          end
                        when /.*_h8300/
                          Elf::Machine::H8300
                        end

      assert_equal(expectedmachine, elf.machine,
                   "ELF machine for #{elf.path} differs from expected machine")
    end
  end

  # Test section flags handling.
  #
  # For each file make sure that .text has at least some flags
  # enabled, like ExecInstr and Alloc.
  def test_text_flags
    @elfs.each_pair do |name, elf|
      assert(elf['.text'],
             "ELF file #{elf.path} does not contain .text section")
      assert(elf['.text'].flags.include?(Elf::Section::Flags::ExecInstr),
             "ELF file #{elf.path}'s .text section is not executable")
      assert(elf['.text'].flags.include?(Elf::Section::Flags::Alloc),
             "ELF file #{elf.path}'s .text section is not allocated")
    end
  end

end
