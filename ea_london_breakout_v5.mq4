//+-----------------------------------------------------------------------------------------------------------------+
//|                                                                                     V1N1 LONY Breakout 5.10.mq4 |
//|                                                                                 Copyright © 2018, Vini Oliveira |
//|                                                                                             vini-fx@hotmail.com |
//+-----------------------------------------------------------------------------------------------------------------+

//=== Program properties
#property copyright   "Copyright © 2018, Vini Oliveira"
#property description "Automated trading system for breakouts in the London and NY sessions."
#property link        "https://www.mql5.com/en/users/vinicius-fx/seller"
#property version     "5.10"
#property strict

//=== Enumerations
enum ENUM_TIME
  {
   H00M00 =     0,   // 00:00
   H01M00 =  3600,   // 01:00
   H02M00 =  7200,   // 02:00
   H03M00 = 10800,   // 03:00
   H04M00 = 14400,   // 04:00
   H05M00 = 18000,   // 05:00
   H06M00 = 21600,   // 06:00
   H07M00 = 25200,   // 07:00
   H08M00 = 28800,   // 08:00
   H09M00 = 32400,   // 09:00
   H10M00 = 36000,   // 10:00
   H11M00 = 39600,   // 11:00
   H12M00 = 43200,   // 12:00
   H13M00 = 46800,   // 13:00
   H14M00 = 50400,   // 14:00
   H15M00 = 54000,   // 15:00
   H16M00 = 57600,   // 16:00
   H17M00 = 61200,   // 17:00
   H18M00 = 64800,   // 18:00
   H19M00 = 68400,   // 19:00
   H20M00 = 72000,   // 20:00
   H21M00 = 75600,   // 21:00
   H22M00 = 79200,   // 22:00
   H23M00 = 82800    // 23:00
  };
enum ENUM_DST
  {
   DstUSA,           // United States (USA)
   DstEuro,          // Europeans Countries
   DstNo             // Not Switch
  };
enum ENUM_RISK
  {
   RiskPerc,         // Percentage
   RiskFixLot        // Fixed Lot
  };

//=== Global input variables
input ENUM_TIME iStartTrade  = H10M00;     // Opening Of The London Session
input ENUM_TIME iEndTrade    = H22M00;     // End Of Trading
input ENUM_DST  iSwitchDST   = DstEuro;    // Switch To DST - Time Zone
input ENUM_RISK iPosRiskBy   = RiskPerc;   // Set Positions Risk By
input double    iPosRisk     = 1.0;        // Positions Risk
input int       iTradeRange  = 12;         // Trading Range - Bars
input double    iBarsUpDn    = 40.0;       // Minimum Bars Up / Down - %
input int       iMinRange    = 200;        // Minimum Range - Points
input int       iMaxRange    = 530;        // Maximum Range - Points
input int       iMinBrkRange = 10;         // Minimum Break Range - Points
input int       iMaxBrkRange = 200;        // Maximum Break Range - Points
input int       iStopLoss    = 100;        // Stop Loss From Range (Points)
input double    iTPfactor    = 1.5;        // Take Profit Factor - Stop Loss
input int       iTrailStop   = 1000;       // Trailing Stop - Points (0 = Off)
input int       iTrendPeriod = 160;        // Trend Period - EMA (0 = Off)
input int       iBarsClose   = 96;         // Bars To Close Positions (0 = Off)
input bool      iOneTrade    = False;      // Only One Trade Per Day
input int       iMaxSpread   = 100;        // Maximum Spread - Points (0 = Off)
input int       iSlippage    = 20;         // Maximum Price Slippage - Points

//=== Global internal variables
int      MagicNumber, ATRperiod = 111;
double   MinBrkRange, MaxBrkRange;
datetime PrevTime, OpenDay = 0;
string   ErrMsg;
//+-----------------------------------------------------------------------------------------------------------------+
//| Expert initialization function                                                                                  |
//+-----------------------------------------------------------------------------------------------------------------+
int OnInit()
  {
   //--- Checks Opening Of The London Session and End Of Trading
   if(iStartTrade >= iEndTrade)
     {
      Alert(Symbol(), Period(), " - Opening Of The London Session or End Of Trading invalid.");
      Print(Symbol(), Period(), " - Opening Of The London Session or End Of Trading invalid.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   //--- Checks Positions Risk
   if(iPosRisk <= 0.0)
     {
      Alert(Symbol(), Period(), " - Positions Risk is required.");
      Print(Symbol(), Period(), " - Positions Risk is required.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   //--- Checks Trading Range
   if(iTradeRange <= 1)
     {
      Alert(Symbol(), Period(), " - Trading Range invalid.");
      Print(Symbol(), Period(), " - Trading Range invalid.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   //--- Checks Minimum Bars Up / Down
   if(iBarsUpDn > 50.0)
     {
      Alert(Symbol(), Period(), " - Minimum Bars Up / Down invalid.");
      Print(Symbol(), Period(), " - Minimum Bars Up / Down invalid.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   //--- Checks Maximum Range
   if(iMaxRange <= 0 || iMaxRange <= iMinRange)
     {
      Alert(Symbol(), Period(), " - Maximum Range invalid.");
      Print(Symbol(), Period(), " - Maximum Range invalid.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   //--- Checks Minimum Break Range
   if(iMinBrkRange <= 0)
     {
      Alert(Symbol(), Period(), " - Minimum Break Range is required.");
      Print(Symbol(), Period(), " - Minimum Break Range is required.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   //--- Checks Maximum Break Range
   if(iMaxBrkRange <= 0)
     {
      Alert(Symbol(), Period(), " - Maximum Break Range is required.");
      Print(Symbol(), Period(), " - Maximum Break Range is required.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   //--- Checks Take Profit Factor
   if(iTPfactor <= 0.0)
     {
      Alert(Symbol(), Period(), " - Take Profit Factor is required.");
      Print(Symbol(), Period(), " - Take Profit Factor is required.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   //--- Initializes variables
   PrevTime    = 0;
   MagicNumber = 11 + Period();
   MinBrkRange = iMinBrkRange * Point;
   MaxBrkRange = iMaxBrkRange * Point;

   return(INIT_SUCCEEDED);
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Expert deinitialization function                                                                                |
//+-----------------------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- Delete comment
   Comment("");
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Expert tick function                                                                                            |
//+-----------------------------------------------------------------------------------------------------------------+
void OnTick()
  {
   //--- Local variables
   double   ATR1, ATR12, ATR0H, ATR0L, Trail, RangeHigh, RangeLow, RangeSize,
            BarsUp = 0.0, BarsDn = 0.0, EMA1, EMA2, SL, TP, Lot;
   bool     DstLon, DstNY, BarsUpDn, OpenOrd, TrendUp = True, TrendDn = True;
   int      Cnt, Ticket = -1, DstHr = 0, ShiftStart;
   datetime StartTrade, EndTrade;

   //--- Delete comment
   Comment("");

   //--- Checks if is trade allowed and history
   if(!IsTradeAllowed() || Bars <= ATRperiod)
     {
      Comment("Trade is not allowed or insufficient history data...");
      Print  ("Trade is not allowed or insufficient history data...");
      return;
     }

   //--- Calculates the Average True Ranges
   ATR1  = iATR(NULL, PERIOD_CURRENT, ATRperiod, 1);
   ATR12 = ATR1 / 2;
   ATR0H = MathAbs(High[0] - Close[1]);
   ATR0L = MathAbs(Low[0]  - Close[1]);

   //--- CHECKS IF IS A NEW BAR...
   if(PrevTime != Time[0] && TimeCurrent() < Time[0] + 180 && ATR12 > ATR0H && ATR12 > ATR0L)
     {
      //--- Checks open positions
      for(Cnt = OrdersTotal() - 1; Cnt >= 0; Cnt--)
        {
         if(OrderSelect(Cnt, SELECT_BY_POS, MODE_TRADES))
           {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
              {
               if(OrderType() == OP_BUY)
                 {
                  //--- Checks if close positions after bars
                  if(iBarsClose > 0 && iBarsClose <= int((Time[0] - OrderOpenTime()) / (Period() * 60)))
                    {
                     if(!OrderClose(OrderTicket(), OrderLots(), Bid, iSlippage, clrBlue))
                       {Print(Symbol(), Period(), " - ", ErrorDescription(GetLastError())); return;}
                    }
                  else
                    {
                     Ticket = OrderTicket();
                     //--- Trailing stop
                     Trail = NormalizeDouble(Bid - iTrailStop * Point, Digits);
                     if(iTrailStop > 0 && OrderOpenPrice() <= Trail && OrderStopLoss() < Trail)
                       {
                        if(!OrderModify(OrderTicket(), OrderOpenPrice(), Trail, OrderTakeProfit(), 0, clrBlue))
                          {Print(Symbol(), " - ", ErrorDescription(GetLastError()));}
                       }
                    }
                 }
               else if(OrderType() == OP_SELL)
                 {
                  //--- Checks if close positions after bars
                  if(iBarsClose > 0 && iBarsClose <= int((Time[0] - OrderOpenTime()) / (Period() * 60)))
                    {
                     if(!OrderClose(OrderTicket(), OrderLots(), Ask, iSlippage, clrRed))
                       {Print(Symbol(), Period(), " - ", ErrorDescription(GetLastError())); return;}
                    }
                  else
                    {
                     Ticket = OrderTicket();
                     //--- Trailing stop
                     Trail = NormalizeDouble(Ask + iTrailStop * Point, Digits);
                     if(iTrailStop > 0 && ((OrderOpenPrice() >= Trail && OrderStopLoss() > Trail) || OrderStopLoss() == 0.0))
                       {
                        if(!OrderModify(OrderTicket(), OrderOpenPrice(), Trail, OrderTakeProfit(), 0, clrRed))
                          {Print(Symbol(), " - ", ErrorDescription(GetLastError()));}
                       }
                    }
                 }
              }
           }
        }

      //--- Checks daylight saving time (DST)
      DstLon = LondonDST();
      DstNY  = NewYorkDST();
      if(iSwitchDST == DstUSA)
        {
         if(!DstLon && DstNY) {DstHr =  3600;}   //--->  3600 sec =  1 hour
         else
         if(DstLon && !DstNY) {DstHr = -3600;}   //---> -3600 sec = -1 hour
        }
      else if(iSwitchDST == DstNo)
        {
         if(DstLon)           {DstHr = -3600;}   //--->  3600 sec =  1 hour
        }

      //--- Calculates trading hours
      StartTrade = StringToTime(TimeToString(TimeCurrent(), TIME_DATE)) + iStartTrade + DstHr;
      EndTrade   = StringToTime(TimeToString(TimeCurrent(), TIME_DATE)) + iEndTrade   + DstHr;

      //--- Checks trading hours
      if(TimeCurrent() < StartTrade || TimeCurrent() >= EndTrade) {PrevTime = Time[0]; return;}

      //--- Calculates trading range
      ShiftStart = iBarShift(NULL, PERIOD_CURRENT, StartTrade, True);
      RangeHigh  = High[iHighest(NULL, PERIOD_CURRENT, MODE_HIGH, iTradeRange, ShiftStart + 1)];
      RangeLow   = Low [iLowest (NULL, PERIOD_CURRENT, MODE_LOW,  iTradeRange, ShiftStart + 1)];
      RangeSize  = (RangeHigh - RangeLow) / Point;

      //--- Checks bars up / down
      for(Cnt = ShiftStart + 1; Cnt < ShiftStart + 1 + iTradeRange; Cnt++)
        {
         if(Open[Cnt] < Close[Cnt]) {BarsUp++;}
         else
         if(Open[Cnt] > Close[Cnt]) {BarsDn++;}
        }
      BarsUpDn = (BarsUp / iTradeRange >= iBarsUpDn / 100 && BarsDn / iTradeRange >= iBarsUpDn / 100);

      //--- Checks conditions to open position
      OpenOrd  = (TimeDay(OpenDay) != TimeDay(TimeCurrent())) || (Ticket < 0 && iOneTrade == False);
      if(RangeSize >= iMinRange && RangeSize <= iMaxRange && BarsUpDn && OpenOrd)
        {
         //--- Calculates the Exponential Moving Averages for Trend
         if(iTrendPeriod > 0)
           {
            EMA1    = iMA(NULL, PERIOD_CURRENT, iTrendPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
            EMA2    = iMA(NULL, PERIOD_CURRENT, iTrendPeriod, 0, MODE_EMA, PRICE_CLOSE, 2);
            TrendUp = EMA1 > EMA2;
            TrendDn = EMA1 < EMA2;
           }

         //--- Checks bullish signal
         if(TrendUp && Open[1] <= RangeHigh && Close[1] >= RangeHigh + MinBrkRange && Close[1] <= RangeHigh + MaxBrkRange)
           {
            //--- Checks spread
            if(iMaxSpread > 0 && iMaxSpread < MarketInfo(Symbol(), MODE_SPREAD))
              {Print(Symbol(), Period(), " - Spread exceeded."); return;}
            //--- Calculates stop loss, take profit, lot and opens position
            SL  = NormalizeDouble(RangeLow - iStopLoss * Point, Digits);
            TP  = NormalizeDouble(Ask + (Ask - SL) * iTPfactor, Digits);
            Lot = CalculateVolume(OP_BUY, SL);
            if(!CheckVolume(Lot))
              {Print(Symbol(), Period(), " - ", ErrMsg);}
            else if(AccountFreeMarginCheck(Symbol(), OP_BUY, Lot) <= 0.0 || _LastError == ERR_NOT_ENOUGH_MONEY)
              {Print(Symbol(), Period(), " - ", ErrorDescription(GetLastError()));}
            else if(OrderSend(Symbol(), OP_BUY, Lot, Ask, iSlippage, SL, TP, "V1N1", MagicNumber, 0, clrBlue) == -1)
              {Print(Symbol(), Period(), " - ", ErrorDescription(GetLastError())); return;}
            else
              {OpenDay = TimeCurrent();}
           }

         //--- Checks bearish signal
         else if(TrendDn && Open[1] >= RangeLow && Close[1] <= RangeLow - MinBrkRange && Close[1] >= RangeLow - MaxBrkRange)
           {
            //--- Checks spread
            if(iMaxSpread > 0 && iMaxSpread < MarketInfo(Symbol(), MODE_SPREAD))
              {Print(Symbol(), Period(), " - Spread exceeded."); return;}
            //--- Calculates stop loss, take profit, lot and opens position
            SL  = NormalizeDouble(RangeHigh + iStopLoss * Point, Digits);
            TP  = NormalizeDouble(Bid - (SL - Bid) * iTPfactor, Digits);
            Lot = CalculateVolume(OP_SELL, SL);
            if(!CheckVolume(Lot))
              {Print(Symbol(), Period(), " - ", ErrMsg);}
            else if(AccountFreeMarginCheck(Symbol(), OP_SELL, Lot) <= 0.0 || _LastError == ERR_NOT_ENOUGH_MONEY)
              {Print(Symbol(), Period(), " - ", ErrorDescription(GetLastError()));}
            else if(OrderSend(Symbol(), OP_SELL, Lot, Bid, iSlippage, SL, TP, "V1N1", MagicNumber, 0, clrRed) == -1)
              {Print(Symbol(), Period(), " - ", ErrorDescription(GetLastError())); return;}
            else
              {OpenDay = TimeCurrent();}
           }
        }
      PrevTime = Time[0];
     }
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Calculate volume function                                                                                       |
//+-----------------------------------------------------------------------------------------------------------------+
double CalculateVolume(int OpType, double SL)
  {
   //--- Local variables
   double MinVolume, MaxVolume, TickValue, VolumeStep, Risk, Lot;
   int    nDigits = 2;

   //--- Minimal and Maximal allowed volume for trade operations
   MinVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   MaxVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);

   //--- Checks Set Positions Risk By
   if(iPosRiskBy == RiskFixLot) {return(iPosRisk);}

   //--- Tick Value
   if(OpType == OP_BUY)
     {TickValue = ((Ask - SL) / Point) * MarketInfo(Symbol(), MODE_TICKVALUE);}
   else   //--- OpType == OP_SELL
     {TickValue = ((SL - Bid) / Point) * MarketInfo(Symbol(), MODE_TICKVALUE);}

   if(TickValue == 0.0)
     {return(MinVolume);}

   //--- Get minimal step of volume changing
   VolumeStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   if(VolumeStep == 0.1) {nDigits = 1;}
   else
   if(VolumeStep == 1.0) {nDigits = 0;}

   //--- Volume Size (Risk Percentage)
   Risk = (AccountBalance() + AccountCredit()) * (iPosRisk / 100);
   Lot  =  NormalizeDouble(Risk / TickValue, nDigits);
   if(Lot < MinVolume) {Lot = MinVolume;}
   else
   if(Lot > MaxVolume) {Lot = MaxVolume;}

   return(Lot);
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Check volume function                                                                                           |
//+-----------------------------------------------------------------------------------------------------------------+
bool CheckVolume(double Lot)
  {
   //--- Minimal allowed volume for trade operations
   double MinVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   if(Lot < MinVolume)
     {
      ErrMsg = StringConcatenate("Volume less than the minimum allowed. The minimum volume is ", MinVolume, ".");
      return(false);
     }

   //--- Maximal allowed volume of trade operations
   double MaxVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   if(Lot > MaxVolume)
     {
      ErrMsg = StringConcatenate("Volume greater than the maximum allowed. The maximum volume is ", MaxVolume, ".");
      return(false);
     }

   //--- Get minimal step of volume changing
   double VolumeStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

   int Ratio = int(MathRound(Lot / VolumeStep));
   if(MathAbs(Ratio * VolumeStep - Lot) > 0.0000001)
     {
      ErrMsg = StringConcatenate("The volume is not multiple of the minimum gradation ", VolumeStep, ". Volume closest to the valid ", Ratio * VolumeStep, ".");
      return(false);
     }

   //--- Correct volume value
   return(true);
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Check London daylight saving time (DST) function                                                                |
//+-----------------------------------------------------------------------------------------------------------------+
bool LondonDST()
  {
   //  ------------>>   London DST Start  ------------>>  London DST End
   if((TimeCurrent() >= D'2000.03.26' && TimeCurrent() <  D'2000.10.29')  ||
      (TimeCurrent() >= D'2001.03.25' && TimeCurrent() <  D'2001.10.28')  ||
      (TimeCurrent() >= D'2002.03.31' && TimeCurrent() <  D'2002.10.27')  ||
      (TimeCurrent() >= D'2003.03.30' && TimeCurrent() <  D'2003.10.26')  ||
      (TimeCurrent() >= D'2004.03.28' && TimeCurrent() <  D'2004.10.31')  ||
      (TimeCurrent() >= D'2005.03.27' && TimeCurrent() <  D'2005.10.30')  ||
      (TimeCurrent() >= D'2006.03.26' && TimeCurrent() <  D'2006.10.29')  ||
      (TimeCurrent() >= D'2007.03.25' && TimeCurrent() <  D'2007.10.28')  ||
      (TimeCurrent() >= D'2008.03.30' && TimeCurrent() <  D'2008.10.26')  ||
      (TimeCurrent() >= D'2009.03.29' && TimeCurrent() <  D'2009.10.25')  ||
      (TimeCurrent() >= D'2010.03.28' && TimeCurrent() <  D'2010.10.31')  ||
      (TimeCurrent() >= D'2011.03.27' && TimeCurrent() <  D'2011.10.30')  ||
      (TimeCurrent() >= D'2012.03.25' && TimeCurrent() <  D'2012.10.28')  ||
      (TimeCurrent() >= D'2013.03.31' && TimeCurrent() <  D'2013.10.27')  ||
      (TimeCurrent() >= D'2014.03.30' && TimeCurrent() <  D'2014.10.26')  ||
      (TimeCurrent() >= D'2015.03.29' && TimeCurrent() <  D'2015.10.25')  ||
      (TimeCurrent() >= D'2016.03.27' && TimeCurrent() <  D'2016.10.30')  ||
      (TimeCurrent() >= D'2017.03.26' && TimeCurrent() <  D'2017.10.29')  ||
      (TimeCurrent() >= D'2018.03.25' && TimeCurrent() <  D'2018.10.28')  ||
      (TimeCurrent() >= D'2019.03.31' && TimeCurrent() <  D'2019.10.27')  ||
      (TimeCurrent() >= D'2020.03.29' && TimeCurrent() <  D'2020.10.25')  ||
      (TimeCurrent() >= D'2021.03.28' && TimeCurrent() <  D'2021.10.31')  ||
      (TimeCurrent() >= D'2022.03.27' && TimeCurrent() <  D'2022.10.30')  ||
      (TimeCurrent() >= D'2023.03.26' && TimeCurrent() <  D'2023.10.29')  ||
      (TimeCurrent() >= D'2024.03.31' && TimeCurrent() <  D'2024.10.27')  ||
      (TimeCurrent() >= D'2025.03.30' && TimeCurrent() <  D'2025.10.26')  ||
      (TimeCurrent() >= D'2026.03.29' && TimeCurrent() <  D'2026.10.25')  ||
      (TimeCurrent() >= D'2027.03.28' && TimeCurrent() <  D'2027.10.31')  ||
      (TimeCurrent() >= D'2028.03.26' && TimeCurrent() <  D'2028.10.29')  ||
      (TimeCurrent() >= D'2029.03.25' && TimeCurrent() <  D'2029.10.28'))

      {return(True);}

   return(False);
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Check New York daylight saving time (DST) function                                                              |
//+-----------------------------------------------------------------------------------------------------------------+
bool NewYorkDST()
  {
   //  ------------>>   NY DST Start   ------------->>   NY DST End
   if((TimeCurrent() >= D'2000.04.02' && TimeCurrent() < D'2000.10.29')  ||
      (TimeCurrent() >= D'2001.04.01' && TimeCurrent() < D'2001.10.28')  ||
      (TimeCurrent() >= D'2002.04.07' && TimeCurrent() < D'2002.10.27')  ||
      (TimeCurrent() >= D'2003.04.06' && TimeCurrent() < D'2003.10.26')  ||
      (TimeCurrent() >= D'2004.04.04' && TimeCurrent() < D'2004.10.31')  ||
      (TimeCurrent() >= D'2005.04.03' && TimeCurrent() < D'2005.10.30')  ||
      (TimeCurrent() >= D'2006.04.02' && TimeCurrent() < D'2006.10.29')  ||
      (TimeCurrent() >= D'2007.03.11' && TimeCurrent() < D'2007.11.04')  ||
      (TimeCurrent() >= D'2008.03.09' && TimeCurrent() < D'2008.11.02')  ||
      (TimeCurrent() >= D'2009.03.08' && TimeCurrent() < D'2009.11.01')  ||
      (TimeCurrent() >= D'2010.03.14' && TimeCurrent() < D'2010.11.07')  ||
      (TimeCurrent() >= D'2011.03.13' && TimeCurrent() < D'2011.11.06')  ||
      (TimeCurrent() >= D'2012.03.11' && TimeCurrent() < D'2012.11.04')  ||
      (TimeCurrent() >= D'2013.03.10' && TimeCurrent() < D'2013.11.03')  ||
      (TimeCurrent() >= D'2014.03.09' && TimeCurrent() < D'2014.11.02')  ||
      (TimeCurrent() >= D'2015.03.08' && TimeCurrent() < D'2015.11.01')  ||
      (TimeCurrent() >= D'2016.03.13' && TimeCurrent() < D'2016.11.06')  ||
      (TimeCurrent() >= D'2017.03.12' && TimeCurrent() < D'2017.11.05')  ||
      (TimeCurrent() >= D'2018.03.11' && TimeCurrent() < D'2018.11.04')  ||
      (TimeCurrent() >= D'2019.03.10' && TimeCurrent() < D'2019.11.03')  ||
      (TimeCurrent() >= D'2020.03.08' && TimeCurrent() < D'2020.11.01')  ||
      (TimeCurrent() >= D'2021.03.14' && TimeCurrent() < D'2021.11.07')  ||
      (TimeCurrent() >= D'2022.03.13' && TimeCurrent() < D'2022.11.06')  ||
      (TimeCurrent() >= D'2023.03.12' && TimeCurrent() < D'2023.11.05')  ||
      (TimeCurrent() >= D'2024.03.10' && TimeCurrent() < D'2024.11.03')  ||
      (TimeCurrent() >= D'2025.03.09' && TimeCurrent() < D'2025.11.02')  ||
      (TimeCurrent() >= D'2026.03.08' && TimeCurrent() < D'2026.11.01')  ||
      (TimeCurrent() >= D'2027.03.14' && TimeCurrent() < D'2027.11.07')  ||
      (TimeCurrent() >= D'2028.03.12' && TimeCurrent() < D'2028.11.05')  ||
      (TimeCurrent() >= D'2029.03.11' && TimeCurrent() < D'2029.11.04'))

      {return(True);}

   return(False);
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Error description function                                                                                      |
//+-----------------------------------------------------------------------------------------------------------------+
string ErrorDescription(int ErrorCode)
  {
   //--- Local variable
   string ErrorMsg;

   switch(ErrorCode)
     {
      //--- Codes returned from trade server
      case 0:    ErrorMsg="No error returned.";                                             break;
      case 1:    ErrorMsg="No error returned, but the result is unknown.";                  break;
      case 2:    ErrorMsg="Common error.";                                                  break;
      case 3:    ErrorMsg="Invalid trade parameters.";                                      break;
      case 4:    ErrorMsg="Trade server is busy.";                                          break;
      case 5:    ErrorMsg="Old version of the client terminal.";                            break;
      case 6:    ErrorMsg="No connection with trade server.";                               break;
      case 7:    ErrorMsg="Not enough rights.";                                             break;
      case 8:    ErrorMsg="Too frequent requests.";                                         break;
      case 9:    ErrorMsg="Malfunctional trade operation.";                                 break;
      case 64:   ErrorMsg="Account disabled.";                                              break;
      case 65:   ErrorMsg="Invalid account.";                                               break;
      case 128:  ErrorMsg="Trade timeout.";                                                 break;
      case 129:  ErrorMsg="Invalid price.";                                                 break;
      case 130:  ErrorMsg="Invalid stops.";                                                 break;
      case 131:  ErrorMsg="Invalid trade volume.";                                          break;
      case 132:  ErrorMsg="Market is closed.";                                              break;
      case 133:  ErrorMsg="Trade is disabled.";                                             break;
      case 134:  ErrorMsg="Not enough money.";                                              break;
      case 135:  ErrorMsg="Price changed.";                                                 break;
      case 136:  ErrorMsg="Off quotes.";                                                    break;
      case 137:  ErrorMsg="Broker is busy.";                                                break;
      case 138:  ErrorMsg="Requote.";                                                       break;
      case 139:  ErrorMsg="Order is locked.";                                               break;
      case 140:  ErrorMsg="Buy orders only allowed.";                                       break;
      case 141:  ErrorMsg="Too many requests.";                                             break;
      case 145:  ErrorMsg="Modification denied because order is too close to market.";      break;
      case 146:  ErrorMsg="Trade context is busy.";                                         break;
      case 147:  ErrorMsg="Expirations are denied by broker.";                              break;
      case 148:  ErrorMsg="The amount of open and pending orders has reached the limit.";   break;
      case 149:  ErrorMsg="An attempt to open an order opposite when hedging is disabled."; break;
      case 150:  ErrorMsg="An attempt to close an order contravening the FIFO rule.";       break;
      //--- Mql4 errors
      case 4000: ErrorMsg="No error returned.";                                             break;
      case 4001: ErrorMsg="Wrong function pointer.";                                        break;
      case 4002: ErrorMsg="Array index is out of range.";                                   break;
      case 4003: ErrorMsg="No memory for function call stack.";                             break;
      case 4004: ErrorMsg="Recursive stack overflow.";                                      break;
      case 4005: ErrorMsg="Not enough stack for parameter.";                                break;
      case 4006: ErrorMsg="No memory for parameter string.";                                break;
      case 4007: ErrorMsg="No memory for temp string.";                                     break;
      case 4008: ErrorMsg="Not initialized string.";                                        break;
      case 4009: ErrorMsg="Not initialized string in array.";                               break;
      case 4010: ErrorMsg="No memory for array string.";                                    break;
      case 4011: ErrorMsg="Too long string.";                                               break;
      case 4012: ErrorMsg="Remainder from zero divide.";                                    break;
      case 4013: ErrorMsg="Zero divide.";                                                   break;
      case 4014: ErrorMsg="Unknown command.";                                               break;
      case 4015: ErrorMsg="Wrong jump (never generated error).";                            break;
      case 4016: ErrorMsg="Not initialized array.";                                         break;
      case 4017: ErrorMsg="Dll calls are not allowed.";                                     break;
      case 4018: ErrorMsg="Cannot load library.";                                           break;
      case 4019: ErrorMsg="Cannot call function.";                                          break;
      case 4020: ErrorMsg="Expert function calls are not allowed.";                         break;
      case 4021: ErrorMsg="Not enough memory for temp string returned from function.";      break;
      case 4022: ErrorMsg="System is busy (never generated error).";                        break;
      case 4023: ErrorMsg="Dll-function call critical error.";                              break;
      case 4024: ErrorMsg="Internal error.";                                                break;
      case 4025: ErrorMsg="Out of memory.";                                                 break;
      case 4026: ErrorMsg="Invalid pointer.";                                               break;
      case 4027: ErrorMsg="Too many formatters in the format function.";                    break;
      case 4028: ErrorMsg="Parameters count exceeds formatters count.";                     break;
      case 4029: ErrorMsg="Invalid array.";                                                 break;
      case 4030: ErrorMsg="No reply from chart.";                                           break;
      case 4050: ErrorMsg="Invalid function parameters count.";                             break;
      case 4051: ErrorMsg="Invalid function parameter value.";                              break;
      case 4052: ErrorMsg="String function internal error.";                                break;
      case 4053: ErrorMsg="Some array error.";                                              break;
      case 4054: ErrorMsg="Incorrect series array using.";                                  break;
      case 4055: ErrorMsg="Custom indicator error.";                                        break;
      case 4056: ErrorMsg="Arrays are incompatible.";                                       break;
      case 4057: ErrorMsg="Global variables processing error.";                             break;
      case 4058: ErrorMsg="Global variable not found.";                                     break;
      case 4059: ErrorMsg="Function is not allowed in testing mode.";                       break;
      case 4060: ErrorMsg="Function is not allowed for call.";                              break;
      case 4061: ErrorMsg="Send mail error.";                                               break;
      case 4062: ErrorMsg="String parameter expected.";                                     break;
      case 4063: ErrorMsg="Integer parameter expected.";                                    break;
      case 4064: ErrorMsg="Double parameter expected.";                                     break;
      case 4065: ErrorMsg="Array as parameter expected.";                                   break;
      case 4066: ErrorMsg="Requested history data is in updating state.";                   break;
      case 4067: ErrorMsg="Internal trade error.";                                          break;
      case 4068: ErrorMsg="Resource not found.";                                            break;
      case 4069: ErrorMsg="Resource not supported.";                                        break;
      case 4070: ErrorMsg="Duplicate resource.";                                            break;
      case 4071: ErrorMsg="Custom indicator cannot initialize.";                            break;
      case 4072: ErrorMsg="Cannot load custom indicator.";                                  break;
      case 4073: ErrorMsg="No history data.";                                               break;
      case 4074: ErrorMsg="No memory for history data.";                                    break;
      case 4075: ErrorMsg="Not enough memory for indicator calculation.";                   break;
      case 4099: ErrorMsg="End of file.";                                                   break;
      case 4100: ErrorMsg="Some file error.";                                               break;
      case 4101: ErrorMsg="Wrong file name.";                                               break;
      case 4102: ErrorMsg="Too many opened files.";                                         break;
      case 4103: ErrorMsg="Cannot open file.";                                              break;
      case 4104: ErrorMsg="Incompatible access to a file.";                                 break;
      case 4105: ErrorMsg="No order selected.";                                             break;
      case 4106: ErrorMsg="Unknown symbol.";                                                break;
      case 4107: ErrorMsg="Invalid price.";                                                 break;
      case 4108: ErrorMsg="Invalid ticket.";                                                break;
      case 4109: ErrorMsg="Trade is not allowed in the Expert Advisor properties.";         break;
      case 4110: ErrorMsg="Longs are not allowed in the Expert Advisor properties.";        break;
      case 4111: ErrorMsg="Shorts are not allowed in the Expert Advisor properties.";       break;
      case 4112: ErrorMsg="Automated trading disabled by trade server.";                    break;
      case 4200: ErrorMsg="Object already exists.";                                         break;
      case 4201: ErrorMsg="Unknown object property.";                                       break;
      case 4202: ErrorMsg="Object does not exist.";                                         break;
      case 4203: ErrorMsg="Unknown object type.";                                           break;
      case 4204: ErrorMsg="No object name.";                                                break;
      case 4205: ErrorMsg="Object coordinates error.";                                      break;
      case 4206: ErrorMsg="No specified subwindow.";                                        break;
      case 4207: ErrorMsg="Graphical object error.";                                        break;
      case 4210: ErrorMsg="Unknown chart property.";                                        break;
      case 4211: ErrorMsg="Chart not found.";                                               break;
      case 4212: ErrorMsg="Chart subwindow not found.";                                     break;
      case 4213: ErrorMsg="Chart indicator not found.";                                     break;
      case 4220: ErrorMsg="Symbol select error.";                                           break;
      case 4250: ErrorMsg="Notification error.";                                            break;
      case 4251: ErrorMsg="Notification parameter error.";                                  break;
      case 4252: ErrorMsg="Notifications disabled.";                                        break;
      case 4253: ErrorMsg="Notification send too frequent.";                                break;
      case 4260: ErrorMsg="FTP server is not specified.";                                   break;
      case 4261: ErrorMsg="FTP login is not specified.";                                    break;
      case 4262: ErrorMsg="FTP connection failed.";                                         break;
      case 4263: ErrorMsg="FTP connection closed.";                                         break;
      case 4264: ErrorMsg="FTP path not found on server.";                                  break;
      case 4265: ErrorMsg="File not found in the Files directory to send on FTP server.";   break;
      case 4266: ErrorMsg="Common error during FTP data transmission.";                     break;
      case 5001: ErrorMsg="Too many opened files.";                                         break;
      case 5002: ErrorMsg="Wrong file name.";                                               break;
      case 5003: ErrorMsg="Too long file name.";                                            break;
      case 5004: ErrorMsg="Cannot open file.";                                              break;
      case 5005: ErrorMsg="Text file buffer allocation error.";                             break;
      case 5006: ErrorMsg="Cannot delete file.";                                            break;
      case 5007: ErrorMsg="Invalid file handle (file closed or was not opened).";           break;
      case 5008: ErrorMsg="Wrong file handle (handle index is out of handle table).";       break;
      case 5009: ErrorMsg="File must be opened with FILE_WRITE flag.";                      break;
      case 5010: ErrorMsg="File must be opened with FILE_READ flag.";                       break;
      case 5011: ErrorMsg="File must be opened with FILE_BIN flag.";                        break;
      case 5012: ErrorMsg="File must be opened with FILE_TXT flag.";                        break;
      case 5013: ErrorMsg="File must be opened with FILE_TXT or FILE_CSV flag.";            break;
      case 5014: ErrorMsg="File must be opened with FILE_CSV flag.";                        break;
      case 5015: ErrorMsg="File read error.";                                               break;
      case 5016: ErrorMsg="File write error.";                                              break;
      case 5017: ErrorMsg="String size must be specified for binary file.";                 break;
      case 5018: ErrorMsg="Incompatible file (for string arrays-TXT, for others-BIN).";     break;
      case 5019: ErrorMsg="File is directory, not file.";                                   break;
      case 5020: ErrorMsg="File does not exist.";                                           break;
      case 5021: ErrorMsg="File cannot be rewritten.";                                      break;
      case 5022: ErrorMsg="Wrong directory name.";                                          break;
      case 5023: ErrorMsg="Directory does not exist.";                                      break;
      case 5024: ErrorMsg="Specified file is not directory.";                               break;
      case 5025: ErrorMsg="Cannot delete directory.";                                       break;
      case 5026: ErrorMsg="Cannot clean directory.";                                        break;
      case 5027: ErrorMsg="Array resize error.";                                            break;
      case 5028: ErrorMsg="String resize error.";                                           break;
      case 5029: ErrorMsg="Structure contains strings or dynamic arrays.";                  break;
      case 5200: ErrorMsg="Invalid URL.";                                                   break;
      case 5201: ErrorMsg="Failed to connect to specified URL.";                            break;
      case 5202: ErrorMsg="Timeout exceeded.";                                              break;
      case 5203: ErrorMsg="HTTP request failed.";                                           break;
      default:   ErrorMsg="Unknown error.";
     }
   return(ErrorMsg);
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Expert End                                                                                                      |
//+-----------------------------------------------------------------------------------------------------------------+
