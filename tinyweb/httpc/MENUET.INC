; new application structure
macro meos_app_start
{
  use32
  org 0x0

  db 'MENUET01'
  dd 0x01
  dd __start
  dd __end
  dd __memory
  dd __stack

  if used __params & ~defined __params
    dd __params
  else
    dd 0x0
  end if

  dd 0x0
}

macro code
{
  __start:
}

macro data
{
  __data:
}

macro udata
{
  if used __params & ~defined __params
    __params:
      db 0
    __end:
      rb 255
  else
    __end:
  end if
  __udata:
}

macro meos_app_end
{
  align 32
  rb 2048
  __stack:
  __memory:
}



; language for programs
lang equ en ; ru en fr ge fi

macro struct name
 {
  virtual at 0
   name name
   sizeof.#name = $ - name
  end virtual
 }

; structures used in MeOS
struc process_information
 {
  .cpu_usage		   dd ?  ; +0
  .window_stack_position   dw ?  ; +4
  .window_stack_value	   dw ?  ; +6
  .not_used1		   dw ?  ; +8
  .process_name 	   rb 12 ; +10
  .memory_start 	   dd ?  ; +22
  .used_memory		   dd ?  ; +26
  .PID			   dd ?  ; +30
  .x_start		   dd ?  ; +34
  .y_start		   dd ?  ; +38
  .x_size		   dd ?  ; +42
  .y_size		   dd ?  ; +46
  .slot_state		   dw ?  ; +50
  rb (1024-52)
 }

struc system_colors
 {
  .frame	    dd ?
  .grab 	    dd ?
  .grab_button	    dd ?
  .grab_button_text dd ?
  .grab_text	    dd ?
  .work 	    dd ?
  .work_button	    dd ?
  .work_button_text dd ?
  .work_text	    dd ?
  .work_graph	    dd ?
 }
struct system_colors