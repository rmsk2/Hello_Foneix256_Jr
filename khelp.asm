; value of event buffer at program start (likely set by `superbasic`)
oldEvent .byte 0, 0
; the new event buffer
myEvent .dstruct kernel.event.event_t


; --------------------------------------------------
; This routine saves the current value of the pointer to the kernel event 
; buffer and sets that pointer to the address of myEvent. This in essence
; disconnects superbasic from the kernel event stream.
;--------------------------------------------------
initEvents
    #move16Bit kernel.args.events, oldEvent
    #load16BitImmediate myEvent, kernel.args.events
    rts


; --------------------------------------------------
; This routine restores the pointer to the kernel event buffer to the value
; encountered at program start. This reconnects superbasic to the kernel
; event stream.
;--------------------------------------------------
restoreEvents
    #move16Bit oldEvent, kernel.args.events
    rts


FKEYS .byte $81, $82, $83, $84, $85, $86, $87, $88

testForFKey
    phx
    ldx #0
_loop
    cmp FKEYS, x
    beq _isFKey
    inx
    cpx #8
    bne _loop
    plx
    clc
    rts
_isFKey
    plx
    sec
    rts


; waiting for a key press event from the kernel
waitForKey
    ; Peek at the queue to see if anything is pending
    lda kernel.args.events.pending ; Negated count
    bpl waitForKey
    ; Get the next event.
    jsr kernel.NextEvent
    bcs waitForKey
    ; Handle the event
    lda myEvent.type    
    cmp #kernel.event.key.PRESSED
    beq _done
    bra waitForKey
_done
    lda myEvent.key.flags 
    and #myEvent.key.META
    beq _isAscii
    lda myEvent.key.raw                                      ; retrieve raw key code
    jsr testForFKey
    bcc waitForKey                                           ; a meta key but not an F-Key was pressed => we are not done
    rts                                                      ; it was an F-Key => return raw key code a ascii value
_isAscii
    lda myEvent.key.ascii
    rts