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
bit         ASI_READY = 0;      //(p) Avalon-ST sink data ready
bit         ASI_VALID = 0;      //(p) Avalon-ST sink data valid
bit [15:0]  ASI_DATA  = 0;      //(p) Avalon-ST sink data
bit         ASO_VALID;          //(p) Avalon-ST source data valid
bit [15:0]  ASO_DATA;           //(p) Avalon-ST source data
bit         ASO_ERROR;          //(p) Avalon-ST source error

// Parameter
parameter ClkCyc    = 10;       // Signal change interval(10ns/50MHz)
parameter ResetTime = 20;       // Reset hold time

// Data rom
bit [15:0] raw_data_rom[1:1024];
bit [15:0] ave_data_rom[1:1024];

int raw_file;
int ave_file;
string line;
int count = 0;

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

/*=============================================================================
 * Input data file read
 *============================================================================*/
initial begin
    count = 0;
    raw_file = $fopen("raw_data.txt", "r");
    while (!$feof(raw_file)) begin
        if ($fgets(line, raw_file)) begin
            raw_data_rom[count] = line.atoi();
            count++;
        end
    end
    $fclose(raw_file);
end


/*=============================================================================
 * Expected data file read
 *============================================================================*/
initial begin
    count = 0;
    ave_file = $fopen("ave_data.txt", "r");
    while (!$feof(ave_file)) begin
        if ($fgets(line, ave_file)) begin
            ave_data_rom[count] = line.atoi();
            count++;
        end
    end
    $fclose(ave_file);
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
    $display("%0s(%0d)Normal data check", `__FILE__, `__LINE__);
    wait(ASI_READY);
    ASI_DATA = 0;
    ASI_VALID = 1'b1;
    @(posedge CLK);
    for (int i=1;i<1024;i++) begin
        @(posedge CLK);
        ASI_DATA = raw_data_rom[i];
        @(posedge CLK);
        wait(ASO_VALID);
        `ChkValue("ASO_DATA", ASO_DATA, ave_data_rom[i]);
    end

    $finish;
end

endmodule
// TB_MOVING_AVE