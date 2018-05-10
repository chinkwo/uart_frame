module		fram_ctrl(
		input		wire			sclk		,
		input		wire			rst_n		,
		input		wire[7:0]	rx_data	,
		input		wire			rx_flag	,
		output	wire[7:0]	tx_data	,
		output	reg	tx_flag1	

);

reg[3:0]		data_cnt	;
reg[5:0]		state			;
reg					wr_en			;
reg[7:0]		wr_addr		;
reg[7:0]		rd_addr		;
reg[15:0]		cnt_10_baud;

parameter	IDLE 	=	0	;
parameter	S_55 	=	1	;
parameter	S_D5 	=	2	;
parameter	S_FA 	=	3	;
parameter	S_WR 	=	4	;
parameter	S_WR1	=	5	;
parameter	S_WR2	=	6	;
parameter	S_RD 	=	7	;
parameter	S_RD1	=	8	;
parameter	S_RD2	=	9	;
parameter	TEN_BAUD	=	52079;


//data_cnt定义
always@(posedge	sclk	or	negedge	rst_n)
	if(rst_n==0)
			data_cnt		<=		0;
	else	if(rx_data==8'h55&&rx_flag==1&&state==IDLE)
			data_cnt		<=		data_cnt+1;
	else	if(rx_data!=8'h55&&rx_flag==1)
			data_cnt		<=		0;		

//状态机定义
always@(posedge	sclk	or	negedge	rst_n)
if(rst_n==0)
		state		<=		IDLE;
else	case(state)
		IDLE  :	if(data_cnt==7)	state	<=	S_55;	
		S_55  :	if(rx_flag==1 	 &&rx_data==8'hd5)	state	<=	S_D5;	  
						else	if(rx_flag==1 	 &&rx_data!=8'hd5)	state	<=	IDLE;	
		S_D5  :	if(rx_flag==1 	 &&rx_data==8'hfa)	state	<=	S_FA;	 
						else	if(rx_flag==1 	 &&rx_data!=8'hfa)	state	<=	IDLE;
		S_FA  :	if(rx_flag==1 	 &&rx_data==8'haa)	state	<=	state + 1;
						else	if(rx_flag==1 	 &&rx_data==8'h55)	state	<=	S_RD;	
						else	if(rx_flag==1 )	state	<=	IDLE;
		S_WR  :	if(rx_flag==1 	 &&rx_data==8'h00)	state	<=	S_WR1;	
						else	if(rx_flag==1 	 &&rx_data!=8'h00)	state	<=	IDLE;
		S_WR1 :	if(rx_flag==1 	 &&rx_data==8'h00)	state	<=	S_WR2;
						else	if(rx_flag==1 	 &&rx_data!=8'h00)	state	<=	IDLE;
		S_WR2 :	if(wr_addr==255&&wr_en==1)	state	<=	IDLE;	
		S_RD  :	if(rx_flag==1 	 &&rx_data==8'h00)	state	<=	S_RD1;	
		S_RD1 :	if(rx_flag==1 	 &&rx_data==8'h00)	state	<=	S_RD2;	
		S_RD2 :	if(rd_addr==255&&cnt_10_baud==TEN_BAUD)	state	<=	IDLE;	
	default:state	<=IDLE;	
		endcase

//wr_en定义
always@(posedge	sclk	or	negedge	rst_n)
		if(rst_n==0)
				wr_en	<=	0;
		else	if(state==S_WR2&&rx_flag==1)
				wr_en	<=	rx_flag	;
		else
				wr_en	<=	0;
				
//wr_addr定义
always@(posedge	sclk	or	negedge	rst_n)
		if(rst_n==0)
				wr_addr	<=	0;
		else	if(wr_addr==255&&wr_en==1)
				wr_addr	<=	0;
		else	if(wr_en==1)
				wr_addr	<=	wr_addr	+	1;
				
						
//cnt_10_baud定义
always@(posedge	sclk	or	negedge	rst_n)
	if(rst_n==0)
			cnt_10_baud		<=		0;
	else	if(cnt_10_baud==TEN_BAUD)
			cnt_10_baud		<=		0;
	else	if(state==S_RD2)
			cnt_10_baud		<=		cnt_10_baud	+	1;
	else	
			cnt_10_baud		<=		0;

//rd_addr定义
always@(posedge	sclk	or	negedge	rst_n)
		if(rst_n==0)
				rd_addr	<=	0;
		else	if(rd_addr==255&&cnt_10_baud==TEN_BAUD)
				rd_addr	<=	0;
		else	if(cnt_10_baud==TEN_BAUD)
				rd_addr	<=	rd_addr	+	1;			
			
			
////tx_data定义
//always@(posedge	sclk	or	negedge	rst_n)
//		if(rst_n==0)
//				tx_data	<=	0;
//		else	
//				tx_data	<=	rd_addr;
	 
//tx_flag1
always@(posedge	sclk	or	negedge	rst_n)
		if(rst_n==0)
				tx_flag1	<=	0;
		else	if(cnt_10_baud==5208)
				tx_flag1	<=	1;
		else	
				tx_flag1	<=	0;
				
//ram例化
ram_256x8 U1 (
  .clka(sclk), // input clka
  .wea(wr_en), // input [0 : 0] wea
  .addra(wr_addr), // input [7 : 0] addra
  .dina(rx_data), // input [7 : 0] dina
  .clkb(sclk), // input clkb
  .addrb(rd_addr), // input [7 : 0] addrb
  .doutb(tx_data) // output [7 : 0] doutb
);

endmodule	