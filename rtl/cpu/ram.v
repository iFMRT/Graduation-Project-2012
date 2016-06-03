//----------------------------------------------------------------------------------
// FILENAME: ram.v
// DESCRIPTION: all of the rams in bramch predictor
// AUTHOR: cjh
// TIME: 2016-05-22 16:02:51
//==================================================================================

module ram9x54(
    input   wire                clk,            // clock
    input   wire[8:0]           ram_addr,       // ram address
    input   wire[53:0]          wd,             // write data
    input   wire                rden,           // is read
    input   wire                wr,             // is write
    output  reg[53:0]           rd              // read data
);
    reg [53:0] ram [512:0];  // t_buffer is a ram

    /******     read data from ram      ******/
    always @(posedge clk) begin
        if (rden) begin
            rd <= ram[ram_addr];    
        end 
    end

    /******     write data to ram       ******/
    always @(posedge clk) begin
        if (wr) begin
            ram [ram_addr] <= wd;   
        end 
    end
endmodule

module ram10x11(
    input   wire                clk,            // clock
    input   wire[9:0]           ram_addr,       // ram address
    input   wire[10:0]          wd,             // write data
    input   wire                rden,           // is read
    input   wire                wr,             // is write
    output  reg[10:0]           rd              // read data
);
    reg [10:0] ram [1023:0];  // t_buffer is a ram

    /******     read data from ram      ******/
    always @(posedge clk) begin
        if (rden) begin
            rd <= ram[ram_addr];    
        end 
    end

    /******     write data to ram       ******/
    always @(posedge clk) begin
        if (wr) begin
            ram [ram_addr] <= wd;   
        end 
    end
endmodule

module ram12x3(
    input   wire                clk,            // clock
    input   wire[11:0]          ram_addr,       // ram address
    input   wire[2:0]           wd,             // write data
    input   wire                rden,           // is read
    input   wire                wr,             // is write
    output  reg[2:0]            rd              // read data
);
    reg [2:0] ram [4095:0];  // t_buffer is a ram

    /******     read data from ram      ******/
    always @(posedge clk) begin
        if (rden) begin
            rd <= ram[ram_addr];    
        end 
    end

    /******     write data to ram       ******/
    always @(posedge clk) begin
        if (wr) begin
            ram [ram_addr] <= wd;   
        end 
    end
endmodule

module ram9x3(
    input   wire                clk,            // clock
    input   wire[8:0]           ram_addr,       // ram address
    input   wire[2:0]           wd,             // write data
    input   wire                rden,           // is read
    input   wire                wr,             // is write
    output  reg[2:0]            rd              // read data
);
    reg [2:0] ram [512:0];  // t_buffer is a ram

    /******     read data from ram      ******/
    always @(posedge clk) begin
        if (rden) begin
            rd <= ram[ram_addr];    
        end 
    end

    /******     write data to ram       ******/
    always @(posedge clk) begin
        if (wr) begin
            ram [ram_addr] <= wd;   
        end 
    end
endmodule