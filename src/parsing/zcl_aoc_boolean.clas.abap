class ZCL_AOC_BOOLEAN definition
  public
  create public .

public section.

  class-methods PARSE
    importing
      !IT_TOKENS type STOKESX_TAB
    returning
      value(RO_NODE) type ref to ZCL_AOC_BOOLEAN_NODE .
protected section.

  class-methods IS_COMPARATOR
    importing
      !IO_TOKENS type ref to ZCL_AOC_BOOLEAN_TOKENS
    returning
      value(RV_COMPARATOR) type I .
  class-methods PARSE_INTERNAL
    importing
      !IO_TOKENS type ref to ZCL_AOC_BOOLEAN_TOKENS
    returning
      value(RO_NODE) type ref to ZCL_AOC_BOOLEAN_NODE .
  class-methods PARSE_NOT
    importing
      !IO_TOKENS type ref to ZCL_AOC_BOOLEAN_TOKENS
    returning
      value(RO_NODE) type ref to ZCL_AOC_BOOLEAN_NODE .
  class-methods PARSE_PAREN
    importing
      !IO_TOKENS type ref to ZCL_AOC_BOOLEAN_TOKENS
    returning
      value(RO_NODE) type ref to ZCL_AOC_BOOLEAN_NODE .
  class-methods REMOVE_METHOD_CALLS
    importing
      !IO_TOKENS type ref to ZCL_AOC_BOOLEAN_TOKENS .
  class-methods SIMPLIFY
    importing
      !IT_TOKENS type STOKESX_TAB
    returning
      value(RO_TOKENS) type ref to ZCL_AOC_BOOLEAN_TOKENS .
  class-methods REMOVE_CALCULATIONS
    importing
      !IO_TOKENS type ref to ZCL_AOC_BOOLEAN_TOKENS .
  class-methods REMOVE_STRINGS
    importing
      !IO_TOKENS type ref to ZCL_AOC_BOOLEAN_TOKENS .
private section.
ENDCLASS.



CLASS ZCL_AOC_BOOLEAN IMPLEMENTATION.


  METHOD is_comparator.

    DATA: lv_token2 TYPE string,
          lv_token3 TYPE string.


    lv_token2 = io_tokens->get_token( 2 )-str.
    lv_token3 = io_tokens->get_token( 3 )-str.

    rv_comparator = 0.

    IF ( lv_token2 = 'IS' AND lv_token3 = 'NOT' )
        OR ( lv_token2 = 'NOT' AND lv_token3 = 'IN' ).
      rv_comparator = 2.
    ELSEIF lv_token2 = 'BETWEEN'.
      rv_comparator = 3.
    ELSEIF lv_token2 = '='
            OR lv_token2 = '<>'
            OR lv_token2 = '<'
            OR lv_token2 = 'GT'
            OR lv_token2 = '>'
            OR lv_token2 = 'LT'
            OR lv_token2 = '>='
            OR lv_token2 = 'GE'
            OR lv_token2 = 'NS'
            OR lv_token2 = '<='
            OR lv_token2 = 'LE'
            OR lv_token2 = 'NE'
            OR lv_token2 = 'CO'
            OR lv_token2 = 'CA'
            OR lv_token2 = 'CS'
            OR lv_token2 = 'CN'
            OR lv_token2 = 'IN'
            OR lv_token2 = 'CP'
            OR lv_token2 = 'NP'
            OR lv_token2 = 'IS'
            OR lv_token2 = 'EQ'.
      rv_comparator = 1.
    ENDIF.

  ENDMETHOD.


  METHOD parse.
* returns initial RO_NODE in case of parser errors

    DATA: lo_tokens TYPE REF TO zcl_aoc_boolean_tokens.


    lo_tokens = simplify( it_tokens ).

    ro_node = parse_internal( lo_tokens ).

  ENDMETHOD.


  METHOD parse_internal.

    DATA: lv_token1     TYPE string,
          lo_node       LIKE ro_node,
          lv_comparator TYPE i.


    lv_token1 = io_tokens->get_token( 1 )-str.

    lv_comparator = is_comparator( io_tokens ).

    IF lv_comparator > 0 AND io_tokens->get_length( ) >= 3.
      CREATE OBJECT ro_node
        EXPORTING
          iv_type = zcl_aoc_boolean_node=>c_type-compare.
      io_tokens->eat( 2 + lv_comparator ).
    ELSEIF lv_token1 = 'NOT'.
      io_tokens->eat( 1 ).
      ro_node = parse_not( io_tokens ).
    ELSEIF lv_token1 = '('.
      ro_node = parse_paren( io_tokens ).
    ELSEIF lv_token1 = 'AND'.
      CREATE OBJECT ro_node
        EXPORTING
          iv_type = zcl_aoc_boolean_node=>c_type-and.
      io_tokens->eat( 1 ).
      lo_node = parse_internal( io_tokens ).
      ro_node->append_child( lo_node ).
    ELSEIF lv_token1 = 'OR'.
      CREATE OBJECT ro_node
        EXPORTING
          iv_type = zcl_aoc_boolean_node=>c_type-or.
      io_tokens->eat( 1 ).
      lo_node = parse_internal( io_tokens ).
      ro_node->append_child( lo_node ).
    ELSE.
* parser error
      RETURN.
    ENDIF.

* parse remaining
    IF io_tokens->get_length( ) > 0.
      lo_node = parse_internal( io_tokens ).
      IF lo_node IS INITIAL.
* parser error
        CLEAR ro_node.
        RETURN.
      ENDIF.
      lo_node->prepend_child( ro_node ).
      ro_node = lo_node.
    ENDIF.

  ENDMETHOD.


  METHOD parse_not.

    DATA: lo_node  TYPE REF TO zcl_aoc_boolean_node,
          lv_end   TYPE i,
          lo_split TYPE REF TO zcl_aoc_boolean_tokens.


    CREATE OBJECT ro_node
      EXPORTING
        iv_type = zcl_aoc_boolean_node=>c_type-not.

    IF io_tokens->get_token( 1 )-str = '('.
      lv_end = io_tokens->find_end_paren( 1 ).
      lo_split = io_tokens->eat( lv_end ).
    ELSE.
      lo_split = io_tokens->eat( 3 ).
    ENDIF.

    lo_node = parse_internal( lo_split ).
    ro_node->append_child( lo_node ).

  ENDMETHOD.


  METHOD parse_paren.

    DATA: lo_node   TYPE REF TO zcl_aoc_boolean_node,
          lv_end    TYPE i,
          lo_split  TYPE REF TO zcl_aoc_boolean_tokens.


    ASSERT io_tokens->get_token( 1 )-str = '('.

    CREATE OBJECT ro_node
      EXPORTING
        iv_type = zcl_aoc_boolean_node=>c_type-paren.

    lv_end = io_tokens->find_end_paren( 1 ).
    lo_split = io_tokens->eat( lv_end ).

* remove start and end paren
    lo_split = lo_split->split(
      iv_start = 1
      iv_end   = lo_split->get_length( ) - 1 ).

    lo_node = parse_internal( lo_split ).
    ro_node->append_child( lo_node ).

  ENDMETHOD.


  METHOD remove_calculations.

    DATA: ls_token  TYPE stokesx,
          ls_prev   LIKE ls_token,
          ls_next   LIKE ls_token,
          lt_tokens TYPE stokesx_tab,
          lv_index  TYPE i.


    lt_tokens = io_tokens->get_tokens( ).

    LOOP AT lt_tokens INTO ls_token WHERE type = scan_token_type-identifier.
      lv_index = sy-tabix.

      CASE ls_token-str.
        WHEN '+' OR '-' OR '*' OR '/' OR 'MOD' OR 'BIT-AND' OR 'BIT-OR'.
          DO 2 TIMES.
            DELETE lt_tokens INDEX lv_index.
          ENDDO.
          lv_index = lv_index - 1.
      ENDCASE.

* remove paren introduced by calculations
      CLEAR: ls_prev, ls_next.
      READ TABLE lt_tokens INDEX lv_index - 1 INTO ls_prev. "#EC CI_SUBRC
      READ TABLE lt_tokens INDEX lv_index + 1 INTO ls_next. "#EC CI_SUBRC
      IF ls_prev-str = '(' AND ls_next-str = ')'.
        DELETE lt_tokens INDEX lv_index + 1.
        DELETE lt_tokens INDEX lv_index - 1.
      ENDIF.
    ENDLOOP.

    io_tokens->set_tokens( lt_tokens ).

  ENDMETHOD.


  METHOD remove_method_calls.

    DATA: ls_token   TYPE stokesx,
          lv_end     TYPE i,
          lv_restart TYPE abap_bool,
          lv_index   TYPE i.


    DO.
      lv_restart = abap_false.
      LOOP AT io_tokens->get_tokens( ) INTO ls_token.
        lv_index = sy-tabix.

        FIND REGEX '^[\w<>~\-=]+\($' IN ls_token-str.
        IF sy-subrc = 0.
          lv_end = io_tokens->find_end_paren( lv_index ).

          io_tokens->replace(
            iv_str   = 'METHOD'
            iv_start = lv_index
            iv_end   = lv_end ).

          lv_restart = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF lv_restart = abap_false.
        EXIT.
      ENDIF.
    ENDDO.

  ENDMETHOD.


  METHOD remove_strings.

    LOOP AT io_tokens->get_tokens( ) TRANSPORTING NO FIELDS WHERE type = scan_token_type-literal.
      io_tokens->replace(
        iv_str   = 'str'
        iv_start = sy-tabix ).
    ENDLOOP.

  ENDMETHOD.


  METHOD simplify.

* todo: string templates?
* todo: change identifiers, so no keywords are possible

    CREATE OBJECT ro_tokens EXPORTING it_tokens = it_tokens.

    remove_strings( ro_tokens ).
    remove_method_calls( ro_tokens ).
    remove_calculations( ro_tokens ).

  ENDMETHOD.
ENDCLASS.
