

class Fixnum

  def to_hex_s
    if $global_dont_append_0x
      return to_s(16)
    else
      return "0x" + to_s(16)
    end
  end

  # bit test set
  def bit_set?(input_bit)
    current_val = to_i
    if (current_val & (1 << input_bit)) != 0
      return true
    else
      return false
    end
  end

  def bit_clear?(input_bit)
    ! bit_set?(input_bit)
  end

  # bochs bcc asm format
  # #0x800FBF7E 
  def to_bcc_hex_s
    "#0x" + to_s(16).upcase
  end

  def to_gass_hex_s
    "$0x" + to_s(16).upcase
  end
  

end

class Bignum

  def to_hex_s
    if $global_dont_append_0x
      return to_s(16)
    else
      return "0x" + to_s(16)
    end
  end

end
