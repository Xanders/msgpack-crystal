class MessagePack::Packer
  def self.new
    new(String::Builder.new)
  end

  def self.new
    packer = new(String::Builder.new)
    yield packer
    packer
  end

  def initialize(io : IO)
    @io = io
  end

  def write(value: Nil | Bool)
    @io.write(pack(value))
    self
  end

  def write(value : String)
    case value.size
    when (0x00..0x1F)
      # fixraw
      @io.write(pack((0xA0 + value.size).to_u8))
      @io.write(value.bytes)
    when (0x0000..0xFFFF)
      # raw16
      @io.write(UInt8[0xDA])
      @io.write(pack(value.size.to_u16))
      @io.write(value.bytes)
    when (0x00000000..0xFFFFFFFF)
      # raw32
      @io.write(UInt8[0xDB])
      @io.write(pack(value.size.to_u32))
      @io.write(value.bytes)
    else
      raise("invalid length")
    end
    self
  end

  def write(value : Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64)
    case value
      when Float32
        @io.write(UInt8[0xCA])
      when Float64
        @io.write(UInt8[0xCB])
      when UInt8
        case value
          when 0x00..0x7f
            # positive fixnum
          else
            @io.write(UInt8[0xCC])
        end
      when UInt16
        @io.write(UInt8[0xCD])
      when UInt32
        @io.write(UInt8[0xCE])
      when UInt64
        @io.write(UInt8[0xCF])
      when Int8
        case value
        when (-0x20..0x7F)
          # positive fixnum, negative fixnum
        else
          @io.write(UInt8[0xD0])
        end
      when Int16
        @io.write(UInt8[0xD1])
      when Int32
        @io.write(UInt8[0xD2])
      when Int64
        @io.write(UInt8[0xD3])
    end
    @io.write(pack(value))
    self
  end

  def write(value : Hash(Type, Type))
    length = value.size
    case length
    when (0x00..0x0F)
      @io.write(pack((0x80 + length).to_u8))
    when (0x0000..0xFFFF)
      @io.write(UInt8[0xDE])
      @io.write(pack(length.to_u16))
    when (0x00000000..0xFFFFFFFF)
      @io.write(UInt8[0xDF])
      @io.write(pack(length.to_u32))
    else
      raise("invalid length")
    end

    value.each do |key, value|
      self.write(key)
      self.write(value)
    end
    self
  end

  def write(value : Array(Type))
    case value.size
    when (0x00..0x0F)
      @io.write(pack((0x90 + value.size).to_u8))
    when (0x0000..0xFFFF)
      @io.write(UInt8[0xDC])
      @io.write(pack(value.size.to_u16))
    when (0x00000000..0xFFFFFFFF)
      @io.write(UInt8[0xDD])
      @io.write(pack(value.size.to_u32))
    else
      raise("invalid length")
    end

    value.each do |item|
      self.write(item)
    end
    self
  end

  private def pack(value : Nil)
    UInt8[0xC0]
  end

  private def pack(value : Bool)
    value ? UInt8[0xC3] : UInt8[0xC2]
  end

  private def pack(value : Int8 | UInt8)
    b1 = (pointerof(value) as UInt8*).value
    UInt8[b1]
  end

  private def pack(value : Int16 | UInt16)
    b1, b2 = (pointerof(value) as {UInt8, UInt8}*).value
    UInt8[b2, b1]
  end

  private def pack(value : Int32 | UInt32 | Float32)
    b1, b2, b3, b4 = (pointerof(value) as {UInt8, UInt8, UInt8, UInt8}*).value
    UInt8[b4, b3, b2, b1]
  end

  private def pack(value : Int64 | UInt64 | Float64)
    b1, b2, b3, b4, b5, b6, b7, b8 = (pointerof(value) as {UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8}*).value
    UInt8[b8, b7, b6, b5, b4, b3, b2, b1]
  end

  def to_s
    @io.to_s
  end

  def bytes
    @io.to_s.bytes
  end
end
