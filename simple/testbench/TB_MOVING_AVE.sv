/*=============================================================================
 * Title        : Moving average testbench
 *
 * File Name    : MOVING_AVE.sv
 * Project      : 
 * Designer     : toms74209200 <https://github.com/toms74209200>
 * Created      : 2023/05/05
 * License      : MIT License.
                  http://opensource.org/licenses/mit-license.php
 *============================================================================*/

`timescale 1ns/1ns

`define Comment(sentence) \
$display("%0s(%0d) %0s.", `__FILE__, `__LINE__, sentence)
`define MessageOK(name, value) \
$display("%0s(%0d) OK:Assertion %0s = %0d.", `__FILE__, `__LINE__, name, value)
`define MessageERROR(name, variable, value) \
$error("%0s(%0d) ERROR:Assertion %0s = %0d failed. %0s = %0d", `__FILE__, `__LINE__, name, value, name, variable)
`define ChkValue(name, variable, value) \
    if ((variable)===(value)) \
        `MessageOK(name, value); \
    else \
        `MessageERROR(name, variable, value);

module TB_MOVING_AVE ;

// Simulation module signal
bit         RESET_n;            //(n) Reset
bit         CLK;                //(p) Clock
bit         ASI_READY;          //(p) Avalon-ST sink data ready
bit         ASI_VALID = 0;      //(p) Avalon-ST sink data valid
bit [15:0]  ASI_DATA  = 0;      //(p) Avalon-ST sink data
bit         ASO_VALID;          //(p) Avalon-ST source data valid
bit [15:0]  ASO_DATA;           //(p) Avalon-ST source data
bit         ASO_ERROR;          //(p) Avalon-ST source error

// Parameter
parameter ClkCyc    = 10;       // Signal change interval(10ns/50MHz)
parameter ResetTime = 20;       // Reset hold time

// Data rom
bit [15:0] raw_data_rom[0:1023];
bit [15:0] ave_data_rom[0:1023];

// module
MOVING_AVE U_MOVING_AVE(
.*,
.ASI_READY(ASI_READY),
.ASI_VALID(ASI_VALID),
.ASI_DATA(ASI_DATA),
.ASO_VALID(ASO_VALID),
.ASO_DATA(ASO_DATA),
.ASO_ERROR(ASO_ERROR)
);

typedef bit[15:0] data_rom_type[0:1023];

function automatic data_rom_type load_file(string file_name);
    int file = $fopen(file_name, "r");
    bit[15:0] data_rom[0:1023];
    string line;
    int count = 0;
    while (!$feof(file)) begin
        if ($fgets(line, file)) begin
            data_rom[count] = line.atohex();
            count += 1;
        end
    end
    $fclose(file);
    return data_rom;
endfunction


/*=============================================================================
 * Load data from file
 *============================================================================*/
initial begin
    raw_data_rom = load_file("raw_data.txt");
    ave_data_rom = load_file("ave_data.txt");
end


/*=============================================================================
 * Clock
 *============================================================================*/
always begin
    #(ClkCyc);
    CLK = ~CLK;
end


/*=============================================================================
 * Reset
 *============================================================================*/
initial begin
    #(ResetTime);
    RESET_n = 1;
end 


/*=============================================================================
 * Signal initialization
 *============================================================================*/
initial begin
    ASI_VALID = 1'b0;
    ASI_DATA = 16'd0;

    #(ResetTime);
    @(posedge CLK);

/*=============================================================================
 * Data check
 *============================================================================*/
    $display("%0s(%0d)Normalized data check", `__FILE__, `__LINE__);
    wait(ASI_READY);
    ASI_DATA = 0;
    @(posedge CLK);
    ASI_VALID = 1'b1;
    for (int i=0;i<128;i++) begin
        ASI_DATA = 16'h7fff;
        @(posedge CLK);
    end
    for (int i=0;i<18;i++) begin
        @(posedge CLK);
    end

    @(posedge CLK);
    ASI_DATA = 0;
    ASI_VALID = 1'b0;
    @(posedge CLK);
    RESET_n = 0;
    @(posedge CLK);
    RESET_n = 1;

    $display("%0s(%0d)Normal data check", `__FILE__, `__LINE__);
    wait(ASI_READY);
    @(posedge CLK);
    ASI_VALID = 1'b1;
    for (int i=0;i<1024;i++) begin
        ASI_DATA = raw_data_rom[i];
        @(posedge CLK);
    end
end

initial begin
    wait(ASO_VALID);
    for (int i=0;i<128;i++) begin
        @(posedge CLK);
    end
    for (int i=0;i<10;i++) begin
        wait(ASO_VALID);
        @(negedge CLK);
        `ChkValue("ASO_DATA", ASO_DATA, 16'h7fff);
    end
    for (int i=0;i<10;i++) begin
        @(posedge CLK);
    end
    for (int i=0;i<1024;i++) begin
        wait(ASO_VALID);
        @(negedge CLK);
        `ChkValue("ASO_DATA", ASO_DATA, ave_data_rom[i]);
    end

    $finish;
end

endmodule
// TB_MOVING_AVE