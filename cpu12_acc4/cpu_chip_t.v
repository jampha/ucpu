//本通用模板仅使用芯片 EPF10K30RC208
//Main board of CPU's design and experiment system
//chip of CPU module is epm7256 or epf10K30,  all pin = 208.
//pin define declare 
//pin assign must change file *.acf for epm7256 or epf10K30
//signal_name's pin number, express such as: RA[1:0] is
//  (epm7256-4,3/epf10K30-207,208) => (pin 3,4/208,207)  

module cpu_chip_t (Reset,RUN,CP,IRQ,STOP,I_END,CK,CK_10K,T,PC,//PC_BP
                RD,EN_W,EN_R,R_A,CBD,AA,
                MA,MD,WC,RC,uD,uA,uCK,uCLK,uCP,t_mode,return_ck); //new add:t_mode,return_ck
                      
  //Ctrl and setup signal ************************

  //when RUN=1(reset=0),there is clock and cycle of CPU, CPU running
  input  Reset;     //(pin 10/11), Reset of soft and hard,from interface
  input  RUN;       //(pin 151/161) from interface of host computer
  input  CP;        //(pin 29/36)   when RUN=1 and pulse CP=1(negedge active),from interface
                    //  setup start_first_address of CPU's program
  input  IRQ;       //(pin 28/31) interrupt request from interface of main computer 
  output STOP;      //(pin 80/83) STOP instruction to interface of main computer
  output I_END;     //(pin 81/85) end of per instruction to interface of main computer
  
  
  //outside or inside timer ************************************

  //because ck connected ck_10k  on board, from interface
  //  so they need synchronously define,else conflict
  //When outside timer: they is clock of CPU_cycle
  //When  inside timer: they is main clock of CPU
  //when RUN=1, ck(=ck_10k) is clock;else there is a lack of clock 
  input  CK;         //(pin 184/79)  use
  input  CK_10K;     //(pin 78/186)  no use
  output return_ck;  //(pin 197) return_ck of CPU's inside timer,out to external
  
  //timer_cycle_direction controll----------------
  output t_mode;     //(pin 195) mode of CPU's timer:  
                     //   =1, outside timer,T is input; =0,inside timer,T out to external
  inout  [3:0] T;    //(pin 6,7,8,9/7,8,9,10) t_mode=1,input;=0,output.

  
  //CPU breakpoint and interface ****************************************
  //1) breakpoint_Logic: in interface
  output [11:0] PC; //(pin 15,16,17,18,19,20,21,22,24,25,26,27
                    //    /15,16,17,18,19,24,25,26,27,28,29,30)
                    //program counters of CPU, goto interface for breakpoint
  /*
  //2) breakpoint_Logic: in CPU   
  //  Pleass open PC_BP in module cpu_chip_m ( )
  //pc's pin new define of breakpoint in CPU, pin be the same as output [11:0] pc;
  //Note: interface rejigger(change), cut breakpoint logic(see face_no.tdf) and
  //send out data and address and cs and write and read from interface
  //can used to setup start_first_address of CPU  
  input [10:0]  pc; //PC[7:0]----data of setup breakpoint etc from interface
                    //AA[4:0]----address of setup breakpoint etc from interface, See back
                    //PC[8]------write order(pulse) of setup breakpoint registers etc 
                    //             from interface
                    //PC[9]------read eable of breakpoint registers etc from interface, can't use
                    //PC[10]-----space chip Of setup breakpoint registers etc from interface,
                    //           PC[10]=cs=op & !aa7 & !aa3 & aa2 & aa1;
  output PC_BP      //viz PC[11]-CPU's program breakpoint output to interface    
  */
  
  //outside 8x4 registers***************************************
  inout  [7:0]  RD; //(pin 40,39,38,37,36,35,34,33/47,46,45,44,41,40,39,38)
                    //data of outside 8x4 registers
                    //if inside, no use  =3s
  output EN_W;      //(pin 48/53) write order(pulse) of outside 8x4 registers
                    //if inside, no use  =1
  output EN_R;      //(pin 49/54) read eable of outside 8x4 registers
                    //if inside, no use  =1
  output [1:0]  R_A;//(pin 4,3/207,208)
                    //read address of outside 8x4 registers, 
                    //if inside, no use  =0
  //callback information  to mian_computer********************************
  output [7:0]  CBD;//(pin 62,61,60,59,58,57,56,55/63,62,61,60,58,57,56,55)
                    //data of callback CPU's information
  input  [4:0]  AA; //(pin 205,204,203,202,201/205,204,203,202,200)
                    //address of mian computer

  // outside memory (viz main memory, CPU and mian_computer share ) *******
  inout  [12:0] MA; //(pin 67,68,69,70,71,86,87,88,89,90,91,92,93/
                    //(    68,69,70,71,73,87,88,89,90,92,93,94,95)
                    //share_address_bus of CPU and interface of mian_computer
                    //when RUN=1, out; else is zzz                
  inout  [7:0]  MD; //(pin 95,96,97, 98, 99,100,101,102/
                    //     96,97,99,100,101,102,103,104)
                    //share_data_bus of CPU and interface of mian_computer
                    //when RUN=1 and wc=1, out; else is zz
  output WC;        //(pin 12/13), write enable of CPU (not pulse)
  output RC;        //(pin 13/14), read enable of CPU
                    //WC and RC goto interface and combination with mian_compute_W/R
  
  //outside micro_memory, CPU only read and mian_computer W/R
  //When use inside micro_memory for FPGA_CPU, outside micromemory no use                 
  input  [23:0] uD; //(pin 108,109,110,111,112,113,114,115,
                    //     117,118,119,120,121,122,123,124,
                    //     133,135,136,137,138,139,140,141/
                    //     111,112,113,114,115,116,119,120,
                    //     121,122,125.126,127,128,131,132,
                    //     141,142,143,144,147,148,149,150)
                    //data of micro_memory
  output [10:0] uA; //(pin 161,163,164,166,167,168,169,170,171,172,173/
                    //     164,166,167,168,169,170,172,173,174,175,176)
                    //address of micro_memory, if RUN=1, ua out;else ua is zz
  //because ucLK connected uCK on board
  input  uCK;       //(pin 182/182) no use, must define
  input  uCLK;      //(pin 181/183) clock of upc(micro_program_counters)  
  input  uCP;       //(pin 77/78) clock of uir(micro_instruction_registers)

 //=============================================================================================
 //begin =======================================================================================
 //一  参数说明 ********************************************************************************
 //调入 cpu_core，本实例为 cpu8tv----单倍时钟的自时序  .clk(CK)
 //形参端口用.形参()表示，其数目取决cpu_core的输入输出端口数，调入时要根据目标cpu_core进行增删
 //    如 CPU是12条以上或微程序控制或其它类型等情况,或者 根据查错观察需要随时增加跟踪的内部信息
 //实参的代入：实参代入相应端口()内，性质和宽度要一致
 //1)可直接用本文输入输出信号作实参代入如.wc(WC)中的WC，
 //    如果不便直接用本文件出入端口信号代入, 如T代入._t()，可使用内部中间变量t 代入，即._t(t)，
 //        因当前CPU是内部时序，T是输出，且T[3]功能不再同t[3]。
 //    注意：这种情况最终要把内部中间变量赋给本文的输出信号或将本文的输入信号赋给内部中间变量
 //          否则错误将被隐藏到编译后的warning内，出现许多非设计要求的warning：Primitive 'xxx'stuck at GND.
 //2)用内部信息如跟踪回收的信息.ac(acc)中的acc
 //3)凡实参使用内部中间变量或内部信息变量如t、acc等，
 //  必须在调用实例CPU核段前声明，注意信号的性质和宽度的一致性，并注意信号的性质和宽度的一致性。
 //      行参名和实参名可同名，但不可混
 
 //二  内部中间变量性的实参声明 ****************************************************************
  wire        cy;
  wire [3:0]  t;
  wire [7:0]  tmp,acc;
  wire [11:0] pc; 
  wire [12:0] o_a;
  wire [15:0] i_reg;
//微程序控制时增加声明
  //wire [7:0]  ua;   //or upc
  //wire [15:0] ud;   //or uir(微程序控制存贮器设计在CPU_CORE)
//用嵌入SRAM 作主存时增加声明
  //wire        wc,rc;
  //wire [7:0]  md;
  //wire [7:0]  ma;  //根据检测程序需要定地址位数

//三  调入你设计的cpu_core ******************************************************************** 
 \cpu8tv cpu_core(  //当前cpu8tv: 单倍时钟的自时序,组合逻辑控制
                   .reset(Reset),       //直接代入
                   .clk(CK),            //直接代入. or .ck(CK) when outside timer，
                   ._t(t),              //内部中间变量,自时序，外时序 ._t(T)
                   //.ck(return_ck),      //直接代入。自时序, 返回到外部
                   .end_i(I_END),       //直接代入,变周期一条指令结束   
                   .wc(WC),             //直接代入
                   .rc(RC),             //  ..
                   .o_d(MD),            //  ..
                   .o_a(o_a),           //内部中间变量,因平台MA是inout
                   .pc(pc),             //内部中间变量,因跟踪回收,内部断点逻辑需要
                   .i_reg(i_reg),       //跟踪回收的信息
                   .ac(acc),            //  ..
                   .cy(cy),             //  ..
                   .tp(tmp),            //  ..
                   //.ua(ua),             //内部中间变量 或 跟踪回收     or (upc)
                   //.ud(ud),             //  ..                         or (uir) 
                   //.uclk(uCLK),         //直接代入, when outside timer 
                   //.ucp(uCP),           //  ..      以下均直接代�    
                   .run(RUN),   //When RUN=0，under CP, pc <= oa;
                   .cp(CP),     //pulse: Debug setup first address of program 
                   .oa(MA)      //when MA_input,used low 10 bit only when 1-2connect of equipment_JP2 
                 );

//四  代人说明: *********************************************************************************
//1）内外时序问题----使用与设置: 见 五段 
//   时序设计在CPU内：.clk(CK)--主时钟输入,生成的周期._t(t) 是输出到外部 
//                    .ck(return_ck)--周期内脉冲,返回输出到外部  
//   时序外部提供：   .ck(CK)--周期内脉冲, ._t(T)  均是输入
//   

//2) return_ck to external
//   如果是自时序、非单倍时钟，打开端口 .ck(return_ck)，注销下面语句，否则不注销
     assign return_ck= CK;   //单倍时钟自时序时

//3) 如果CPU用固定周期，可注销.end_i(I_END), 按情况选下面一句打开：
     //assign I_END = t[max]; //内部时序
     //assign I_END = T[max]; //外部时序

//4) 使用嵌入 SRAM 作主存
//   A 请打开用嵌入SRAM 作主存时用的中间变量声明,并代入:.wc(wc),.rc(rc),.o_d(md),.o_a(ma),
//   B 对MA的输出处理为3态高阻,见 六 段
//         用74465时,其中 1'b0 => 1'b1,以禁止打开3态门(高阻)
//       或用assign, 其中 RUN  => 1'b0,仅选择高组
//   C 对MD的输出处理为3态高阻,请打开下语句:
       //\74465 MD_busl(.gn({1'b1,1'b0}),.a(8'hFF),.y(MD));  
//   D 对CPU_Core的实例设计的修改（主要是访问存贮器的数据由双向改为读、写分开）,见十二段 B
//        并按要求作打开或注销相应的逻辑描述语句段 
//   E 若嵌入 SRAM 作主存已设计在CPU_Core的实例中, 返回.wc(wc),.rc(rc),.o_d(md),.o_a(ma),
//         用于跟踪回收
//   F 对WC，RC的输出无�处理----即打开下2个语句
       //assign WC=1'b0;
       //assign RC=1'b0;
//   G 哈佛HV结构的程序和数据存贮器设计类同嵌入rom、SRAM, SRAM也可选用外部SRAM.
//         其逻辑描述可在本文,也可在CPU_Core的实例中,也可交叉放置。
//         实例代入端口与参数、所需的跟踪回收、相关处理，据CPU_Core的实例设计、参考本文类似情况进行。
//   H 使用 SRAM 作主存时,读主存(外部)查看运行结果方法已不可用,必须:
//     a 对测试程序*.bin,要在自身循环结束程序前把结果(如果有寄存器组)或结果累加到累加器看跟踪回收信息.
//     b 如禁止外部主存片选(改接口EPM7256逻辑),RC改为输入,RUN=0时Debug可读SRAM,但比较麻烦.

//5) 不用的高位地址o_a 和 pc 处理（如4条指令的CPU）：打开下面两语句
     //assign o_a[12:0]=5'b00000;
     //assign pc[11:0]=4'b0000;

//6) 不用的低字节指令寄存器 i_reg 处理 （如4条指令的CPU）：打开下面语句
     //assign i_reg[7:0] = 8'h00;

//7) 跟踪回收信息正好是模板仿真时的入出信息，特别是为观察内部信息而使其输出。
//   新增的跟踪回收信息在后面 十段 <信息跟踪回收>段添加输出：
//       可用尚未用的地址单元，
//       或者用当前已不用的地址单元。
//注:PC是输出时,跟踪在外部进行,
//   PC输入时,Debug窗口程序计数器显示的内容实际不是CPU_PC,所以必须在<信息跟踪回收>段添加回收

//8) 使用微程序控制的微存: 
//   a 请打开微程序用的中间变量声明和代入端口,如是自时序(非外部),则.uclk()和.ucp()不打开.
//     若微存设计在CPU_Core的实例中,则跟踪回收宜用upc,uir
//   b 见十一 micro_PROGRAM_Ctrl段,按要求作打开或注销相应的逻辑描述语句段
 
//9) 如果知道测试程序启动首地址，可在cpu_core内用异步复位设置到pc：pc_o <= 12'h00e;
//       并注销.run(RUN),.cp(CP),.oa(MA), 
//   否则 在cpu_core内增加设置语句：pc_o <= {2'b00,oa[9:0];    均见下 
/*
  wire _ck = ck | cp；  //cp 是下降的后沿有�,所以下面必须是 negedge _ck 
  always @(negedge _ck or posedge reset ) 
   begin
      if ( reset)
        pc_o <= 12'h000; 
        //pc_o <= 12'h00e; //知道测试程序启动首地址=00e H   
      else if (run==0)     //CPU不运行时, 接口发启动首地址，在CP下打入PC
        pc_o <= {2'b00,oa[9:0]; //平台JP4的1-2连仅用低10位
      else
      casex ({irh[7:5],t,cy_reg})
        ………………
*/

//10）如果CPU使用外部寄存器组----见七段
//    程序断点设置与所在位置(在CPU_core或本模板或外部)----见八段
//    停机处理----见九段 

 
//五 timer 内部或外部的控制 ******************************************************************
//if CPU is inside timer,then mode_t=0,else =1; 
   wire mode_t=0;  //same with t_mode, =0, because cpu8tv is inside timer
   assign t_mode = mode_t; 

//FUNCTION TRI (in, oe)
//   RETURNS (out);
\tri _t0(.in(t[0]),.oe(!mode_t),.out(T[0]));
\tri _t1(.in(t[1]),.oe(!mode_t),.out(T[1]));
\tri _t2(.in(t[2]),.oe(!mode_t),.out(T[2]));
\tri _t3(.in(t[3]),.oe(!mode_t),.out(T[3]));
 
//六  地址MA必须作3态双向处理，可选择 1) 或 2) ***************************************************
//    这是因存贮器共享和设置程序启动首地址需要
// 1) 用74465
//\74465 MA_busl(.gn({~RUN,1'b0}),.a(o_a[7:0]),.y(MA[7:0]));    //若需禁止打开3态门,则1'b0 => 1'b1
//\74465 MA_bush(.gn({~RUN,1'b0}),.a(o_a[12:8]),.y(MA[12:8]));  //  ..
// 2) 用assign
assign MA = RUN?(o_a):13'bz_zzzz_zzzz_zzzz;          //only 10k30 若需输出高阻,则 RUN  => 1'b0

//七  外部寄存器组控制 **************************************************************************
//如果当前使用外部寄存器组，在调入cpu_core的端口中,
//    如EN_W,EN_R,R_A,RD将作实参代入,请注销下面 4句:
//如果当前不使用外部寄存器组,用以下 4句 作无�处理:
assign EN_W=1;
assign EN_R=1;
assign R_A=2'b00;
// 寄存器数据RD的3态处理 可选择 1 或 2 或 3
//assign RD = 1'b0 ? 8'h00:8'hzz;                     //1 for chip_EPM7256 and chip_10K30,have warning  
//\74465 RD_bus(.gn({1'b1,1'b0}),.a(8'hFF),.y(RD));   //2 for chip_EPM7256 and chip_10K30,have warning
assign RD = 8'hzz;                                    //3 for chip_10K30 only, no warning    


//八  brekpoint logic 处理*************************************************************************

//1) 如果 brekpoint logic 在外部,打开 assign PC=pc;----推荐 
//       同时 module的PC属性声明要 打开 1),注销 2)
//          注销 brekpoint logic 描述段
//2) 如果 brekpoint logic 在本模板,PC[10:0]是输入,要注销 assign PC=pc; 
//       同时 module()内增加PC_BP,前面的PC属性声明要 注销 1),打开 2)
//          打开 brekpoint logic 描述段 1) 或 2) 
//       注意：brekpoint logic 在内部即2)与3)--不推荐使用
//3) 如果 断点逻辑设计在CPU_core, module()内增加PC_BP,前面的PC属性声明要 注销 1),打开 2) 
//       PC[10:0]按新定义要输入到CPU_core,PC_BP从CPU_core输出,要注销 assign PC=pc
//       在调入cpu_core中要增加相应的端口与参数:       
//           .aa(AA),._d(PC[7:0]),..wr(PC[8]),.cs(PC[10]),.pc_bt(PC_BP)     
//   注意: 为保证PC[10:0],PC_BP符合断点在内部即2)与3)的定义与功能.
//         cpu_chip即EPF10K30编程(烧写)前,先用faceN_usb文件夹的face_b.pof编程接口用EPM7256    
  
     assign PC=pc;

//brekpoint logic in cpu_chip  的描述======================================== 
//brekpoint registers of USB_8051 ctrl_address a9=1
//本模板信号 定义     CPU_core的信号与声明
// AA[4:0]--address----input  aa[4:0];
// PC[7:0]--data-------input  _d[7:0];
// PC[8]----write------input  wr; 
// PC[10]---片选-------input  cs; 
// PC_BP----断点-------output pc_bP;

// 可选择 1) 或 2) 两种方式 

/*                   
// 1) immediacy describe  111111111111111111111111

wire[7:0] _D=PC[7:0];  //input
wire WR=PC[8];    //input        
wire cs=PC[10];   //input  "0" active
 
wire en_b_rl = !cs & !AA[0];
wire en_b_rh = !cs &  AA[0];
                    
reg[11:0] bp_r;
reg PC_BP;

always @(negedge WR or posedge reset )
  begin
    if (Reset)
      bp_r <= 0;
    else if (en_b_rl)   bp_r [7:0] <= _D;
    else if (en_b_rh)   bp_r[11:8] <= _D[3:0];
  end
  
 always @(bp_r or pc)   // pc from CPU_core
   begin
	 if (bp_r==pc)
	    PC_BP <=1;
	 else 
	    PC_BP <=0;
   end

  */

// 2) use instance--不推荐  2222222222222222222222
  /*
  \bkpt bp(.reset(Reset),
           .AA0(AA[0]),
           .PC_BP(PC_BP),
           .chip_PC(PC[10:0]),
           .cpu_pc(pc),
           );
  */

  //九  停机处理 ****************************************************************************
  //When online test of cpu run in cpu experiment system  need
  assign STOP  = 1'b0;  // When no STOP instruction else = OP_code of STOP instruction

   
  //十 信息跟踪回收：feedback cpu'S inside information  from CPU core************************
  //       可根据需要,自定义跟踪回收的信息
  //       可选择 1) 或 2) 两种方式
  //1) immediacy describe   111111111111111111111111
  //   (When no suffice 8 bit,fill in "GND")
  reg [7:0] qq;
  always @(AA[4:0])
    begin
      casex(AA[4:0])
        5'b00000:
          qq <= MA[7:0];              //low 8 bit of inside/outside address bus   
        5'b00001:
          qq <= {4'b0000,MA[11:8]};   //high bit of inside/outside address bu        
        5'b00010:
          qq <= MD;                   //inside/outside data bus
        5'b00011:
          qq <= acc[7:0];             //accumulator register
        //5'b00100: 
          //qq <= 8'b00000000;          //ACT_temp REG   no use
        5'b00101:
          qq <= tmp[7:0];               //TEMP REG
        //5'b00110:
          //qq <= 0;                     //REG0  可用作 ud/uir[7:0]  
        //5'b00111:
          //qq <= 0;                     //REG1  可用作 ud/uir[15:8]
        //5'b01000:
          //qq <= 0;                     //REG2  可用作 ud/uir[23:16]    
        //5'b01001:
          //qq <= 0;                     //REG3     
        5'b01010:
          begin
            qq[0]   <= 1'b0;          //status ZF no use
            qq[1]   <= cy;            //carry
            qq[7:2] <= 6'b000000;     //no use 74181
            //qq[7..2]=(s[],m,cn0);     //74181 alu_op
          end  
        //5'b01011:
        // qq <=8'b00000000;            //ALU out
        5'b01100:
          qq <=i_reg[15:8];          //instruction register high 8 bit
        5'b01101:
          qq <=i_reg[7:0];           //instruction register low 8 bit  
        //5'b01111:
          //qq <=8'b00000000;       //CTRL and enable signal 1, 可用作 ua/upc
        //5'b11111:
          //qq <= 8'b00000000;      //CTRL and enable signal 2, 可用作 ua/upc 
        default: 
          qq <= 8'b00000000;
      endcase
    end

  SOFT soft1(qq[0],CBD[0]);  //加缓冲以便于器件内部资源分配
  SOFT soft2(qq[1],CBD[1]);
  SOFT soft3(qq[2],CBD[2]);
  SOFT soft4(qq[3],CBD[3]);
  SOFT soft5(qq[4],CBD[4]);
  SOFT soft6(qq[5],CBD[5]);
  SOFT soft7(qq[6],CBD[6]);
  SOFT soft8(qq[7],CBD[7]);
  
//2) use instance--不推荐 2222222222222222222222222222  
 /* 
 \callback (.mal(ma[7:0]),
            .mah({3'b000,ma[12:8]}),
            .md(md),
            .acc(acc),
            //.act_reg0(),
            .tmp_reg1(tmp),
            .reg2(pc[7:0]),
            .reg3({4'b0000,pc[11:8]}),
            .alu_sop({6'b000000,cy,1'b0}),
            //.alu_out(),
            .irh(i_reg[15:8]),
            .irl(i_reg[7:0]),
            //.Ctrla(),
            .Ctrlb({6'b000000,wc,rc}),
            .AA(AA),
            .CBD(CBD)
            );

 */

//=========================================================================================
//=========================================================================================
//十一 micro_PROGRAM_Ctrl  ****************************************************************
  //A 非微程序控制 或 用内部ROM作微程序控制存贮器时,打开下句,否则要注销,
  assign uA=0;
  //B 微程序控制存贮器在外部时,打开uD和uA, 否则保持注销
    //assign uD=ud; 
    //  因微存共享(主机写读微存),地址必须作3态处理(不用的高位地址=0)，可选择 1) 或 2) 形式
    // 1) 用 assign  
    //assign uA = RUN?(ua):11'bzzz_zzzz_zzzz; 
    // 2) 用74465  
    //\74465 uA_busl(.gn({~RUN,1'b0}),.a(ua[7:0]),.y(uA[7:0]));
    //\74465 uA_bush(.gn({~RUN,1'b0}),.a(ua[10:8]),.y(uA[10:8]));

  //c 微程序控制存贮器设计在CPU_CORE 或 微程序控制存贮器在外部时,全注销下段描述============  
    // 否则,嵌入 ROM 作 微程序控制存贮器,可选择打开 1) 或 2) 方式
    // asynchronism_ROM memory 
    //lpm_rom 库功能: 
    //FUNCTION lpm_rom (address[LPM_WIDTHAD-1..0], 
    //                  inclock, outclock, memenab)
    //	WITH (LPM_WIDTH, LPM_WIDTHAD, LPM_NUMWORDS, 
    //        LPM_FILE, LPM_ADDRESS_CONTROL, LPM_OUTDATA)
    //	RETURNS (q[LPM_WIDTH-1..0]);

// 1) 直接描述   111111111111111111111111111 
/* 
\lpm_rom um (.address(ua),.q(ud));
  defparam
		um.LPM_WIDTH = 16,     //数据位数,取决所需微码位数
		um.LPM_WIDTHAD = 5,    //地址位数,取决微程序总条数               
		um.LPM_ADDRESS_CONTROL = "UNREGISTERED",  //异步
		um.LPM_OUTDATA = "UNREGISTERED",          // ..
		um.LPM_FILE = "cpu8u_um.mif";  //微程序码（HEX）文件，在同目录不要路径
*/

// 2) 调用实例--不推荐 2222222222222222222222
/*
\cpu_um_rom um(
               .address(ua),
	           .q(ud)
               );
*/

//===================================================================================
//===================================================================================
//十二  嵌入SRAM 作主存--不推荐******************************************************
   //使用嵌入SRAM 作主存,请首先打开下句,以产生写脉冲 we,
   //    直接用写命令(允许或选通),将会错误的写

   //wire we = wc & CK;

// A) 异步、数据双向IO的SRAM(库)--现不可用 ##########################################
//   注意: 因芯片内部不能描述3态(仅能在IO入出脚描述),
//         所以在*.v文件内,嵌入SRAM不能用异步、数据双向IO方式,
//         否则编译不是3态驱动错误,就是对数据两次赋值。
//         但在图形编辑器可用----编译自动将双向分成输入、输出两个内部变量
//lpm_ram_io 库功能:  
//FUNCTION lpm_ram_io (address[LPM_WIDTHAD-1..0], we, 
//                     inclock, outclock, outenab, memenab)
//	WITH (LPM_WIDTH, LPM_WIDTHAD, LPM_NUMWORDS, 
//        LPM_FILE, LPM_INDATA, LPM_ADDRESS_CONTROL, LPM_OUTDATA)
//	RETURNS (dio[LPM_WIDTH-1..0]);
//    we--写脉冲,outenab--读选通,memenab--存贮器片选可省缺,均=1有�
 
// 可选择打开 1 或 2 方式 
// 1) 直接描述  111111111111111111111111111111 
/*
\lpm_ram_io mm (.address(o_a),.we(we),.outenab(rc),.dio(o_d));
    defparam
		mm.LPM_WIDTH   = 8,                      //数据宽度
		mm.LPM_WIDTHAD = 8,                      //地址宽度
		//mm.LPM_NUMWORD =256,                     //存贮器单元数
        mm.LPM_INDATA = "UNREGISTERED",          //数据输入不寄存，不要inclock
		mm.LPM_ADDRESS_CONTROL = "UNREGISTERED", //地址输入不寄存，不要inclock
		mm.LPM_OUTDATA = "UNREGISTERED",         //输出数据不寄存，不要outclock
		mm.LPM_FILE = "cpu8u_mm.mif",             //运行的目标（HEX）文件，在同目录不要路径
		mm.LPM_HINT = "UNUSED",                  //for VHDL 
        //mm.LPM_TYPE = "LPM_RAM_IO",              //类型：双向
        mm.USE_EAB	= "ON";                      //FPGA隐藏块使用
 */

//  2) 调用实例--不推荐  2222222222222222222222
 /* 
 \cpu_mm_io mm_io(.address(ma),
	              .we(we),
	              .outenab(rc),
	              .dio(MA)
                  );

 */


// B) 异步、数据的输入d与输出q分开的SRAM(库)  ############################################
//   注意：该方式对CPU_Core的实例设计要求的修改：         
//         1)写到存贮器的数据（d）和从存贮器读的数据(q)要分开,
//           否则仍会编译不是3态驱动错误,就是对数据两次赋值。
//         2)数据总线 o_d 属性声明改 inout 为 input,即o_d=md=q
//           写输出数据直接由结果寄存器如累加器等输出
//               本实例改后d(data)=ac=acc.
//         3)注销原数据输出用3态缓冲74465语句
     
//lpm_ram_dq 库功能: 
//FUNCTION lpm_ram_dq (data[LPM_WIDTH-1..0], address[LPM_WIDTHAD-1..0], 
//                     inclock, outclock, we)
//	WITH (LPM_WIDTH, LPM_WIDTHAD, LPM_NUMWORDS, LPM_FILE, LPM_INDATA,
//        LPM_ADDRESS_CONTROL, LPM_OUTDATA)
//	RETURNS (q[LPM_WIDTH-1..0]);

// 可选择打开 1 或 2 方式 
// 1) 直接描述  111111111111111111111111111111
/*
\lpm_ram_dq mm(.data(acc),
              .address(ma), 
              .we(we),
              //.inclock(_ck), //地址和we输入寄存clock，与LPM_ADDRESS_CONTROL对应
              .q(md));
   defparam
        mm.LPM_WIDTH = 8,
		mm.LPM_WIDTHAD = 8,
		//mm.LPM_NUMWORDS = 256,
		mm.LPM_INDATA = "UNREGISTERED",
		mm.LPM_ADDRESS_CONTROL = "UNREGISTERED",
		mm.LPM_OUTDATA = "UNREGISTERED",
        mm.LPM_FILE = "cpu8u_mm.mif",
        mm.LPM_TYPE = "LPM_RAM_DQ",
		mm.LPM_HINT = "UNUSED";
  */

// 2) 调用实例--不推荐 2222222222222222222222222
  /*   
   \cpu_mm_dq mm_dq(.address(ma),
	                .we(we),
	                .data(acc),
	                .q(md)
                   );
  */




endmodule

