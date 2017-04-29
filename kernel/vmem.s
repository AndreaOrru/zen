.type setupPaging, @function

////
// Enable the paging system.
//
// Arguments:
//     phys_pd: Physical pointer to the page directory.
//
setupPaging:
  mov eax, [esp + 4]  // Fetch the phys_pd parameter.
  mov cr3, eax        // Point CR3 to the page directory.

  // Enable Page Size Extension and Page Global.
  mov eax, cr4
  or eax, 0b10010000
  mov cr4, eax

  // Enable Paging.
  mov eax, cr0
  or eax, (1 << 31)
  mov cr0, eax

  ret
