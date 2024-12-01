/// Converts an address to its higher half equivalent.
///
/// Parameters:
///   address: Lower or higher half address.
///
/// Returns:
///   Higher half address.
pub inline fn higherHalf(address: usize) usize {
    return address | 0xFFFF_8000_0000_0000;
}
