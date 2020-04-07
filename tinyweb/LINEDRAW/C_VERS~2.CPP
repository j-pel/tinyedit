457:  ///////////////////////////////////////////////////////////////////////////////
458:  // DrawBresenhamLine()
459:  //
460:  //  Description:
461:  //      Routine to draw a line on the given surface from x1, y1 to x2, y2
462:  //      with the given R, G, and B color components. Uses the Bresenham
463:  //      algorithm for the line.
464:  //
465:  //  Input:
466:  //      - Buffer to draw on
467:  //      - Pitch of a line (in dwords per line)
468:  //      - X1, Y1 and X2, Y2 Coordinates
469:  //      - Red, Green, and Blue color components
470:  //
471:  //  Output:
472:  //      - N/A
473:  //
474:  //  Speed:
475:  //      - Random Seed of 100
476:  //      - 300,000 Lines
477:  //      - 5.810 Seconds
478:  //      - 51,635 lines per second
479:  //
480:  //      - Drawing a line from (0, 0) - (799, 599)
481:  //      - Is 1K pixels per line
482:  //      - Runs around 17,000 lines per second
483:  //      - Total of 17,000,000 pixels per second
484:  //
485:  ///////////////////////////////////////////////////////////////////////////////
486:  void DrawBresenhamLine(void* buffer, int pitch, int x1, int y1, int x2, int y2,
487:                         Uint8 R, Uint8 G, Uint8 B)
488:  {
00402C50   push        ebp
00402C51   mov         ebp,esp
00402C53   sub         esp,6Ch
00402C56   push        ebx
00402C57   push        esi
00402C58   push        edi
00402C59   lea         edi,[ebp-6Ch]
00402C5C   mov         ecx,1Bh
00402C61   mov         eax,0CCCCCCCCh
00402C66   rep stos    dword ptr [edi]
489:      int x, y;
490:      int index;
491:      int dx, dy;
492:      int incx, incy;
493:      int iErrorTerm;
494:      DWORD* pBuffer = (DWORD*)buffer;
00402C68   mov         eax,dword ptr [ebp+8]
00402C6B   mov         dword ptr [ebp-24h],eax
495:      DWORD color;
496:
497:      // We are always going to draw top to bottom so swap things if needed
498:      if( y1 > y2 )
00402C6E   mov         ecx,dword ptr [ebp+14h]
00402C71   cmp         ecx,dword ptr [ebp+1Ch]
00402C74   jle         DrawBresenhamLine+4Ah (00402c9a)
499:      {
500:          int Temp = y1;
00402C76   mov         edx,dword ptr [ebp+14h]
00402C79   mov         dword ptr [Temp],edx
501:          y1 = y2;
00402C7C   mov         eax,dword ptr [ebp+1Ch]
00402C7F   mov         dword ptr [ebp+14h],eax
502:          y2 = Temp;
00402C82   mov         ecx,dword ptr [Temp]
00402C85   mov         dword ptr [ebp+1Ch],ecx
503:          Temp = x1;
00402C88   mov         edx,dword ptr [ebp+10h]
00402C8B   mov         dword ptr [Temp],edx
504:          x1 = x2;
00402C8E   mov         eax,dword ptr [ebp+18h]
00402C91   mov         dword ptr [ebp+10h],eax
505:          x2 = x1;
00402C94   mov         ecx,dword ptr [ebp+10h]
00402C97   mov         dword ptr [ebp+18h],ecx
506:      }
507:
508:      // Is our X Axis moving in a positive direction?
509:      if( x2 >= x1 )
00402C9A   mov         edx,dword ptr [ebp+18h]
00402C9D   cmp         edx,dword ptr [ebp+10h]
00402CA0   jl          DrawBresenhamLine+64h (00402cb4)
510:      {
511:          // Yes, we are going positive so calculate
512:          // the distance and set the X increment to be
513:          // a positive 1
514:          dx = x2 - x1;
00402CA2   mov         eax,dword ptr [ebp+18h]
00402CA5   sub         eax,dword ptr [ebp+10h]
00402CA8   mov         dword ptr [ebp-10h],eax
515:          incx = 1;
00402CAB   mov         dword ptr [ebp-18h],1
516:      }
517:      else
00402CB2   jmp         DrawBresenhamLine+74h (00402cc4)
518:      {
519:          // No, we are going negative so calculate
520:          // the distance and set the X increment to be
521:          // a negative 1
522:          dx = x1 - x2;
00402CB4   mov         ecx,dword ptr [ebp+10h]
00402CB7   sub         ecx,dword ptr [ebp+18h]
00402CBA   mov         dword ptr [ebp-10h],ecx
523:          incx = -1;
00402CBD   mov         dword ptr [ebp-18h],0FFFFFFFFh
524:      }
525:
526:      // Since the Y is always positive we can just
527:      // calc the distance and set the Y increment to be
528:      // a positive 1
529:      dy = y2 - y1;
00402CC4   mov         edx,dword ptr [ebp+1Ch]
00402CC7   sub         edx,dword ptr [ebp+14h]
00402CCA   mov         dword ptr [ebp-14h],edx
530:      incy = 1;
00402CCD   mov         dword ptr [ebp-1Ch],1
531:
532:      // Set the current X and Y coordinate to the start
533:      // of the line specified
534:      x = x1;
00402CD4   mov         eax,dword ptr [ebp+10h]
00402CD7   mov         dword ptr [ebp-4],eax
535:      y = y1;
00402CDA   mov         ecx,dword ptr [ebp+14h]
00402CDD   mov         dword ptr [ebp-8],ecx
536:
537:      // Set our starting point for the buffer
538:      pBuffer = (DWORD*)buffer + (y * pitch) + x;
00402CE0   mov         edx,dword ptr [ebp-8]
00402CE3   imul        edx,dword ptr [ebp+0Ch]
00402CE7   mov         eax,dword ptr [ebp+8]
00402CEA   lea         ecx,[eax+edx*4]
00402CED   mov         edx,dword ptr [ebp-4]
00402CF0   lea         eax,[ecx+edx*4]
00402CF3   mov         dword ptr [ebp-24h],eax
539:
540:      // Compute the color we will use
541:      color = (R << 16 | G << 8 | B);
00402CF6   mov         ecx,dword ptr [ebp+20h]
00402CF9   and         ecx,0FFh
00402CFF   shl         ecx,10h
00402D02   mov         edx,dword ptr [ebp+24h]
00402D05   and         edx,0FFh
00402D0B   shl         edx,8
00402D0E   or          ecx,edx
00402D10   mov         eax,dword ptr [ebp+28h]
00402D13   and         eax,0FFh
00402D18   or          ecx,eax
00402D1A   mov         dword ptr [ebp-28h],ecx
542:
543:      // Special case the horixontal, vertical, and diagonal lines
544:      // since they don't need "normal calculations"
545:
546:      // Is the line vertical?
547:      if( dx == 0 )
00402D1D   cmp         dword ptr [ebp-10h],0
00402D21   jne         DrawBresenhamLine+108h (00402d58)
548:      {
549:          // The line is vertical
550:          for(index = 0; index <= dy; index++)
00402D23   mov         dword ptr [ebp-0Ch],0
00402D2A   jmp         DrawBresenhamLine+0E5h (00402d35)
00402D2C   mov         ecx,dword ptr [ebp-0Ch]
00402D2F   add         ecx,1
00402D32   mov         dword ptr [ebp-0Ch],ecx
00402D35   mov         edx,dword ptr [ebp-0Ch]
00402D38   cmp         edx,dword ptr [ebp-14h]
00402D3B   jg          DrawBresenhamLine+103h (00402d53)
551:          {
552:              // Draw the pixel at the current location
553:              *pBuffer = color;
00402D3D   mov         eax,dword ptr [ebp-24h]
00402D40   mov         ecx,dword ptr [ebp-28h]
00402D43   mov         dword ptr [eax],ecx
554:
555:              // Move down one line
556:              pBuffer += pitch;
00402D45   mov         edx,dword ptr [ebp+0Ch]
00402D48   mov         eax,dword ptr [ebp-24h]
00402D4B   lea         ecx,[eax+edx*4]
00402D4E   mov         dword ptr [ebp-24h],ecx
557:          }
00402D51   jmp         DrawBresenhamLine+0DCh (00402d2c)
558:
559:          // Done drawing
560:          return;
00402D53   jmp         DrawBresenhamLine+265h (00402eb5)
561:      }
562:
563:      // Is the line horizontal?
564:      if( dy == 0 )
00402D58   cmp         dword ptr [ebp-14h],0
00402D5C   jne         DrawBresenhamLine+143h (00402d93)
565:      {
566:          // The line is horizontal
567:          for(index = 0; index <= dx; index++)
00402D5E   mov         dword ptr [ebp-0Ch],0
00402D65   jmp         DrawBresenhamLine+120h (00402d70)
00402D67   mov         edx,dword ptr [ebp-0Ch]
00402D6A   add         edx,1
00402D6D   mov         dword ptr [ebp-0Ch],edx
00402D70   mov         eax,dword ptr [ebp-0Ch]
00402D73   cmp         eax,dword ptr [ebp-10h]
00402D76   jg          DrawBresenhamLine+13Eh (00402d8e)
568:          {
569:              // Draw the pixel at the current location
570:              *pBuffer = color;
00402D78   mov         ecx,dword ptr [ebp-24h]
00402D7B   mov         edx,dword ptr [ebp-28h]
00402D7E   mov         dword ptr [ecx],edx
571:
572:              // Move to the next pixel on this line
573:              pBuffer += incx;
00402D80   mov         eax,dword ptr [ebp-18h]
00402D83   mov         ecx,dword ptr [ebp-24h]
00402D86   lea         edx,[ecx+eax*4]
00402D89   mov         dword ptr [ebp-24h],edx
574:          }
00402D8C   jmp         DrawBresenhamLine+117h (00402d67)
575:
576:          // Done drawing
577:          return;
00402D8E   jmp         DrawBresenhamLine+265h (00402eb5)
578:      }
579:
580:      // Is this line diagonal
581:      if( dx == dy )
00402D93   mov         eax,dword ptr [ebp-10h]
00402D96   cmp         eax,dword ptr [ebp-14h]
00402D99   jne         DrawBresenhamLine+183h (00402dd3)
582:      {
583:          // The line is diagonal
584:          for(index = 0; index <= dx; index++)
00402D9B   mov         dword ptr [ebp-0Ch],0
00402DA2   jmp         DrawBresenhamLine+15Dh (00402dad)
00402DA4   mov         ecx,dword ptr [ebp-0Ch]
00402DA7   add         ecx,1
00402DAA   mov         dword ptr [ebp-0Ch],ecx
00402DAD   mov         edx,dword ptr [ebp-0Ch]
00402DB0   cmp         edx,dword ptr [ebp-10h]
00402DB3   jg          DrawBresenhamLine+17Eh (00402dce)
585:          {
586:              // Draw the pixel at the current location
587:              *pBuffer = color;
00402DB5   mov         eax,dword ptr [ebp-24h]
00402DB8   mov         ecx,dword ptr [ebp-28h]
00402DBB   mov         dword ptr [eax],ecx
588:
589:              // Move down one line and over by the x increment
590:              pBuffer += (pitch + incx);
00402DBD   mov         edx,dword ptr [ebp+0Ch]
00402DC0   add         edx,dword ptr [ebp-18h]
00402DC3   mov         eax,dword ptr [ebp-24h]
00402DC6   lea         ecx,[eax+edx*4]
00402DC9   mov         dword ptr [ebp-24h],ecx
591:          }
00402DCC   jmp         DrawBresenhamLine+154h (00402da4)
592:
593:          // Done drawing
594:          return;
00402DCE   jmp         DrawBresenhamLine+265h (00402eb5)
595:      }
596:
597:      // Is this an X major or Y major line?
598:      if( dx >= dy )
00402DD3   mov         edx,dword ptr [ebp-10h]
00402DD6   cmp         edx,dword ptr [ebp-14h]
00402DD9   jl          DrawBresenhamLine+1F9h (00402e49)
599:      {
600:          // The line is X Major
601:
602:          // Scale the Y length up by a factor of 2
603:          // Compute the starting ErrorTerm
604:          // Then scale the X length up by a factor of 2
605:          dy <<= 1;
00402DDB   mov         eax,dword ptr [ebp-14h]
00402DDE   shl         eax,1
00402DE0   mov         dword ptr [ebp-14h],eax
606:          iErrorTerm = dy - dx;
00402DE3   mov         ecx,dword ptr [ebp-14h]
00402DE6   sub         ecx,dword ptr [ebp-10h]
00402DE9   mov         dword ptr [ebp-20h],ecx
607:          dx <<= 1;
00402DEC   mov         edx,dword ptr [ebp-10h]
00402DEF   shl         edx,1
00402DF1   mov         dword ptr [ebp-10h],edx
608:
609:          // Loop until we reach the end of the X axis
610:          while( x != x2 )
00402DF4   mov         eax,dword ptr [ebp-4]
00402DF7   cmp         eax,dword ptr [ebp+18h]
00402DFA   je          DrawBresenhamLine+1EFh (00402e3f)
611:          {
612:              // Draw the pixel at the current location
613:              *pBuffer = color;
00402DFC   mov         ecx,dword ptr [ebp-24h]
00402DFF   mov         edx,dword ptr [ebp-28h]
00402E02   mov         dword ptr [ecx],edx
614:
615:              // Does our ErrorTerm indicate we need to move to
616:              // the next pixel on our minor axis (the Y axis)?
617:              if( iErrorTerm >= 0 )
00402E04   cmp         dword ptr [ebp-20h],0
00402E08   jl          DrawBresenhamLine+1CFh (00402e1f)
618:              {
619:                  // Move to the next Y line in the buffer
620:                  pBuffer += pitch;
00402E0A   mov         eax,dword ptr [ebp+0Ch]
00402E0D   mov         ecx,dword ptr [ebp-24h]
00402E10   lea         edx,[ecx+eax*4]
00402E13   mov         dword ptr [ebp-24h],edx
621:
622:                  // Adjust the error term back down again
623:                  iErrorTerm -= dx;
00402E16   mov         eax,dword ptr [ebp-20h]
00402E19   sub         eax,dword ptr [ebp-10h]
00402E1C   mov         dword ptr [ebp-20h],eax
624:              }
625:
626:              // Add another Y delta on since we moved a pixel
627:              // along the X axis
628:              iErrorTerm += dy;
00402E1F   mov         ecx,dword ptr [ebp-20h]
00402E22   add         ecx,dword ptr [ebp-14h]
00402E25   mov         dword ptr [ebp-20h],ecx
629:
630:              // Move to the next coordinate along the X axis
631:              x += incx;
00402E28   mov         edx,dword ptr [ebp-4]
00402E2B   add         edx,dword ptr [ebp-18h]
00402E2E   mov         dword ptr [ebp-4],edx
632:              pBuffer += incx;
00402E31   mov         eax,dword ptr [ebp-18h]
00402E34   mov         ecx,dword ptr [ebp-24h]
00402E37   lea         edx,[ecx+eax*4]
00402E3A   mov         dword ptr [ebp-24h],edx
633:          }
00402E3D   jmp         DrawBresenhamLine+1A4h (00402df4)
634:
635:          // Draw the pixel at the final location
636:          *pBuffer = color;
00402E3F   mov         eax,dword ptr [ebp-24h]
00402E42   mov         ecx,dword ptr [ebp-28h]
00402E45   mov         dword ptr [eax],ecx
637:      }
638:      else
00402E47   jmp         DrawBresenhamLine+265h (00402eb5)
639:      {
640:          // The line is Y major
641:
642:          // Scale the X length up by a factor of 2
643:          // Compute the starting ErrorTerm
644:          // Then scale the Y length up by a factor of 2
645:          dx <<= 1;
00402E49   mov         edx,dword ptr [ebp-10h]
00402E4C   shl         edx,1
00402E4E   mov         dword ptr [ebp-10h],edx
646:          iErrorTerm = dx - dy;
00402E51   mov         eax,dword ptr [ebp-10h]
00402E54   sub         eax,dword ptr [ebp-14h]
00402E57   mov         dword ptr [ebp-20h],eax
647:          dy <<= 1;
00402E5A   mov         ecx,dword ptr [ebp-14h]
00402E5D   shl         ecx,1
00402E5F   mov         dword ptr [ebp-14h],ecx
648:
649:          // Loop until we reach the end of the Y axis
650:          while( y != y2 )
00402E62   mov         edx,dword ptr [ebp-8]
00402E65   cmp         edx,dword ptr [ebp+1Ch]
00402E68   je          DrawBresenhamLine+25Dh (00402ead)
651:          {
652:              // Draw a pixel at the current location
653:              *pBuffer = color;
00402E6A   mov         eax,dword ptr [ebp-24h]
00402E6D   mov         ecx,dword ptr [ebp-28h]
00402E70   mov         dword ptr [eax],ecx
654:
655:              // Does our ErrorTerm indicate we need to move to
656:              // the next pixel on our minor axis (the X axis)?
657:              if( iErrorTerm >= 0 )
00402E72   cmp         dword ptr [ebp-20h],0
00402E76   jl          DrawBresenhamLine+23Dh (00402e8d)
658:              {
659:                  // Move to the next X coordinate in the buffer
660:                  pBuffer += incx;
00402E78   mov         edx,dword ptr [ebp-18h]
00402E7B   mov         eax,dword ptr [ebp-24h]
00402E7E   lea         ecx,[eax+edx*4]
00402E81   mov         dword ptr [ebp-24h],ecx
661:
662:                  // Adjust the error term back down again
663:                  iErrorTerm -= dy;
00402E84   mov         edx,dword ptr [ebp-20h]
00402E87   sub         edx,dword ptr [ebp-14h]
00402E8A   mov         dword ptr [ebp-20h],edx
664:              }
665:
666:              // Add another X delta on since we moved a pixel
667:              // along the Y axis
668:              iErrorTerm += dx;
00402E8D   mov         eax,dword ptr [ebp-20h]
00402E90   add         eax,dword ptr [ebp-10h]
00402E93   mov         dword ptr [ebp-20h],eax
669:
670:              // Move to the next coordinate along the Y axis
671:              y += incy;
00402E96   mov         ecx,dword ptr [ebp-8]
00402E99   add         ecx,dword ptr [ebp-1Ch]
00402E9C   mov         dword ptr [ebp-8],ecx
672:              pBuffer += pitch;
00402E9F   mov         edx,dword ptr [ebp+0Ch]
00402EA2   mov         eax,dword ptr [ebp-24h]
00402EA5   lea         ecx,[eax+edx*4]
00402EA8   mov         dword ptr [ebp-24h],ecx
673:          }
00402EAB   jmp         DrawBresenhamLine+212h (00402e62)
674:
675:          // Draw the pixel at the final location
676:          *pBuffer = color;
00402EAD   mov         edx,dword ptr [ebp-24h]
00402EB0   mov         eax,dword ptr [ebp-28h]
00402EB3   mov         dword ptr [edx],eax
677:      }
678:
679:      // Done drawing
680:      return;
681:  }
00402EB5   pop         edi
00402EB6   pop         esi
00402EB7   pop         ebx
00402EB8   mov         esp,ebp
00402EBA   pop         ebp
00402EBB   ret
