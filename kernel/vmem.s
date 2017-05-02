.type setupPaging, @function

////
// Enable the paging system.
//
// Arguments:
//     phys_pd: Physical pointer to the page directory.
//
setupPaging:
  mov +4(%esp), %eax  // Fetch the phys_pd parameter.
  mov %eax, %cr3      // Point CR3 to the page directory.

  // Enable Page Size Extension and Page Global.
  mov %cr4, %eax
  or $0b10010000, %eax
  mov %eax, %cr4

  // Enable Paging.
  mov %cr0, %eax
  or $(1 << 31), %eax
  mov %eax, %cr0

  ret
