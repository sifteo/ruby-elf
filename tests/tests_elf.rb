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
    if !self.class::ExpectedVersion.nil?
      assert_equal(self.class::ExpectedVersion, @elf.version,
                   "Unexpected ELF version")
    end
  end

  # Test for ELF file type
  ExpectedFileType = nil

  def test_elf_filetype
    if !self.class::ExpectedFileType.nil?
      assert_equal(self.class::ExpectedFileType, @elf.type,
                   "Unexpected ELF file type")
    end
  end

  # Test for ELF class
  ExpectedElfClass = nil

  def test_elf_class
    if !self.class::ExpectedElfClass.nil?
      assert_equal(self.class::ExpectedElfClass, @elf.elf_class,
                   "Unexpected ELF class")
    end
  end

  # Test for ELF endiannes
  ExpectedDataEncoding = nil

  def test_elf_dataencoding
    if !self.class::ExpectedDataEncoding.nil?
      assert_equal(self.class::ExpectedDataEncoding, @elf.data_encoding,
                   "Unexpected ELF data encoding")
    end
  end

  # Test for ELF ABI
  ExpectedABI = nil

  def test_elf_abi
    if !self.class::ExpectedABI.nil?
      assert_equal(self.class::ExpectedABI, @elf.abi,
                   "Unexpected ELF ABI")
    end
  end

  # Test for ELF ABI version
  ExpectedABIVersion = nil

  def test_elf_abi_version
    if !self.class::ExpectedABIVersion.nil?
      assert_equal(self.class::ExpectedABIVersion, @elf.abi_version,
                   "Unexpected ELF ABI version")
    end
  end

  # Test for ELF Machine
  ExpectedMachine = nil

  def test_elf_abi_version
    if !self.class::ExpectedMachine.nil?
      assert_equal(self.class::ExpectedMachine, @elf.machine,
                   "Unexpected ELF machine")
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

class Elf::TestExecutable < Elf::TestUnit
  ExpectedSections = [ ".text" ]

  # Test section flags handling.
  #
  # For each file make sure that .text has at least some flags
  # enabled, like ExecInstr and Alloc.
  def test_text_flags
    assert(@elf['.text'].flags.include?(Elf::Section::Flags::ExecInstr),
           "ELF file #{@elf.path}'s .text section is not executable")
    assert(@elf['.text'].flags.include?(Elf::Section::Flags::Alloc),
           "ELF file #{@elf.path}'s .text section is not allocated")
  end

  module LinuxX86
    ExpectedElfClass = Elf::Class::Elf32
    ExpectedDataEncoding = Elf::DataEncoding::Lsb
    ExpectedABI = Elf::OsAbi::SysV
    ExpectedABIVersion = 0
    ExpectedMachine = Elf::Machine::I386
  end

  module LinuxAMD64
    ExpectedElfClass = Elf::Class::Elf64
    ExpectedDataEncoding = Elf::DataEncoding::Lsb
    ExpectedABI = Elf::OsAbi::SysV
    ExpectedABIVersion = 0
    ExpectedMachine = Elf::Machine::X8664
  end

  module LinuxSparc
    ExpectedElfClass = Elf::Class::Elf32
    ExpectedDataEncoding = Elf::DataEncoding::Msb
    ExpectedABI = Elf::OsAbi::SysV
    ExpectedABIVersion = 0
    ExpectedMachine = Elf::Machine::Sparc32Plus
  end

  module LinuxArm
    ExpectedElfClass = Elf::Class::Elf32
    ExpectedDataEncoding = Elf::DataEncoding::Lsb
    ExpectedABI = Elf::OsAbi::ARM
    ExpectedABIVersion = 0
    ExpectedMachine = Elf::Machine::ARM
  end

  module SolarisX86_GCC
    ExpectedElfClass = Elf::Class::Elf32
    ExpectedDataEncoding = Elf::DataEncoding::Lsb
    ExpectedABI = Elf::OsAbi::SysV
    ExpectedABIVersion = 0
    ExpectedMachine = Elf::Machine::I386
  end

  module SolarisX86_SunStudio
    ExpectedElfClass = Elf::Class::Elf32
    ExpectedDataEncoding = Elf::DataEncoding::Lsb
    ExpectedABI = Elf::OsAbi::SysV
    ExpectedABIVersion = 0
    ExpectedMachine = Elf::Machine::I386
  end

  module BareH8300
    ExpectedElfClass = Elf::Class::Elf32
    ExpectedDataEncoding = Elf::DataEncoding::Msb
    ExpectedABI = Elf::OsAbi::SysV
    ExpectedABIVersion = 0
    ExpectedMachine = Elf::Machine::H8300
  end

end
