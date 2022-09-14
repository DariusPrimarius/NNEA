bool          cci_highest      = FALSE;
bool          cci_lowest       = FALSE;
bool          trade_sell       = FALSE;
bool          trade_buy        = FALSE;
double        last_order_price = 0;
double        band_high        = 0;
double        band_low         = 0;
double        i_lots           = 0;
int           initial_deposit  = 0;
int           total_orders     = 0;
int           iterations       = 0;
int           lotdecimal       = 2;
int           prev_time        = 0;
int           timeout          = 86400;
int           order__time      = 0;
int           magic_num        = 2222;
int           error            = 0;
int           slip             = 100;
extern double bands_dev        = 1;
extern double exp              = 1.5;
extern double lots             = 0.01;
uint          time_start       = GetTickCount();
string        name             = "Ilan1.6";

#include "AngryNetwork.mq4";

Network* my_network;

int init()
{
    initial_deposit = AccountBalance();
    my_network = new Network(5, 4, 2);
    UpdateBeforeOrder();
    UpdateAfterOrder();
    Debug();
    return 0;
}

int deinit()
{
    uint time_elapsed = GetTickCount() - time_start;

    for (int i = 0; i < ArraySize(my_network.input_layer); i++)
        delete(my_network.input_layer[i]);
        
    for (int q = 0; q < ArraySize(my_network.hidden_layer); q++)
        delete(my_network.hidden_layer[q]);
        
    for (int s = 0; s < ArraySize(my_network.output_layer); s++)
        delete(my_network.output_layer[s]);
    delete my_network;
    return 0;
}

int start()
{
    if (!IsTesting() || IsVisualMode()) Debug();

    /* Idle conditions */
    if (prev_time == Time[0]) return 0;
    prev_time = Time[0];
    UpdateBeforeOrder();

    /* Closes all orders if there are any */
    RefreshRates();
    if (AccountProfit() > 0.00 /* && trade_buy && !cci_lowest */) CloseAllOrders();
    // if (AccountProfit() > 0.01 && trade_sell && !cci_highest) CloseAllOrders();
    
    /* Checks Timeout with no orders active*/
    //if (OrdersTotal() == 0 && Time[0] - order__time > timeout * 7 && IsTesting())
    //  Kill();
    
    /* First order */
    if (OrdersTotal() == 0)
    {
        if (cci_highest) SendOrder(OP_SELL);
        if (cci_lowest) SendOrder(OP_BUY);
        return 0;
    }

    /* Checks Timeout */
    //if (OrdersTotal() > 0 && Time[0] - order__time > timeout && IsTesting())
    //    Kill();

    /* Proceeding orders */
    if (trade_sell && cci_highest && band_low  > last_order_price) SendOrder(OP_SELL);
    if (trade_buy  && cci_lowest  && band_high < last_order_price) SendOrder(OP_BUY );
    return 0;
}

void UpdateBeforeOrder()
{
    band_high      = Ask * (1 + bands_dev / 100);
    band_low       = Bid * (1 - bands_dev / 100);

    my_network.input_layer[0].output = iMFI(0, 0, 10, 1) / 100;
    my_network.input_layer[1].output = iDeMarker(0, 0, 10, 1);
    my_network.input_layer[2].output = (iRVI(0, 0, 10, MODE_SIGNAL, 1) + 1) / 2;
    my_network.input_layer[3].output = iStochastic(0, 0, 10, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1) / 100;
    my_network.input_layer[4].output = (iCCI(0, 0, 10, PRICE_TYPICAL, 1) + 350 ) / 700;
    
    my_network.hidden_layer[0].weights[0] = weight_11;
    my_network.hidden_layer[0].weights[1] = weight_12;
    my_network.hidden_layer[0].weights[2] = weight_13;
    my_network.hidden_layer[0].weights[3] = weight_14;
    my_network.hidden_layer[0].weights[4] = weight_15;
    
    my_network.hidden_layer[1].weights[0] = weight_21;
    my_network.hidden_layer[1].weights[1] = weight_22;
    my_network.hidden_layer[1].weights[2] = weight_23;
    my_network.hidden_layer[1].weights[3] = weight_24;
    my_network.hidden_layer[1].weights[4] = weight_25;

    my_network.hidden_layer[2].weights[0] = weight_31;
    my_network.hidden_layer[2].weights[1] = weight_32;
    my_network.hidden_layer[2].weights[2] = weight_33;
    my_network.hidden_layer[2].weights[3] = weight_34;
    my_network.hidden_layer[2].weights[4] = weight_35;
    
    my_network.hidden_layer[3].weights[0] = weight_41;
    my_network.hidden_layer[3].weights[1] = weight_42;
    my_network.hidden_layer[3].weights[2] = weight_43;
    my_network.hidden_layer[3].weights[3] = weight_44;
    my_network.hidden_layer[3].weights[4] = weight_45;
    
    my_network.output_layer[0].weights[0] = o_weight_11;
    my_network.output_layer[0].weights[1] = o_weight_12;
    my_network.output_layer[0].weights[2] = o_weight_13;
    my_network.output_layer[0].weights[3] = o_weight_14;
    
    my_network.output_layer[1].weights[0] = o_weight_21;
    my_network.output_layer[1].weights[1] = o_weight_22;
    my_network.output_layer[1].weights[2] = o_weight_23;
    my_network.output_layer[1].weights[3] = o_weight_24;
    
    my_network.hidden_layer[0].threshhold = threshhold_1;
    my_network.hidden_layer[1].threshhold = threshhold_2;
    my_network.hidden_layer[2].threshhold = threshhold_3;
    my_network.hidden_layer[3].threshhold = threshhold_4;
    
    my_network.output_layer[0].threshhold = o_threshhold_1;
    my_network.output_layer[1].threshhold = o_threshhold_2;
    
    my_network.FeedForward();
    
    if (my_network.output_layer[0].output >= 0.5 && my_network.output_layer[1].output < 0.5) cci_highest = True; else cci_highest = False;
    if (my_network.output_layer[1].output >= 0.5 && my_network.output_layer[0].output < 0.5) cci_lowest  = True; else cci_lowest  = False;
}

void UpdateAfterOrder()
{
    double multiplier = exp(OrdersTotal());
    i_lots            = NormalizeDouble(lots * multiplier, lotdecimal);

    error = OrderSelect(OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES);
    last_order_price = OrderOpenPrice();

    /* In case user modifies a previous order */
    for (int i = 0; i < OrdersTotal() - 1; i++)
    {
        error = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);

        if (OrderOpenPrice() > last_order_price && OrderType() == OP_SELL)
            last_order_price = OrderOpenPrice();
        if (OrderOpenPrice() < last_order_price && OrderType() == OP_BUY)
            last_order_price = OrderOpenPrice();
    }

    if (OrdersTotal() == 0)
    {
        total_orders     = 0;
        order__time      = Time[0];
        trade_sell       = FALSE;
        trade_buy        = FALSE;
    }
    else if (OrderType() == OP_SELL)
    {
        total_orders     = OrdersTotal();
        order__time      = Time[0];
        trade_sell       = TRUE;
        trade_buy        = FALSE;
    }
    else if (OrderType() == OP_BUY)
    {
        total_orders     = OrdersTotal();
        order__time      = Time[0];
        trade_sell       = FALSE;
        trade_buy        = TRUE;
    }
    else
    {
        Alert("Critical error " + GetLastError());
    }
}

void SendOrder(int OP_TYPE)
{
    if (OP_TYPE == OP_SELL)
        error = OrderSend(Symbol(), OP_TYPE, i_lots, Bid, slip, 0, 0, name,
                          magic_num, 0, clrHotPink);
    if (OP_TYPE == OP_BUY)
        error = OrderSend(Symbol(), OP_TYPE, i_lots, Ask, slip, 0, 0, name,
                          magic_num, 0, clrLimeGreen);

    if (IsTesting()  && error < 0) Kill();
    if (!IsTesting() && error < 0) Print("Order failed\n.");
    UpdateAfterOrder();
}

void CloseAllOrders()
{
    color clr = clrBlue;
    if (Time[0] - order__time > timeout) clr = clrGold;

    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        error = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderType() == OP_BUY)
            error = OrderClose(OrderTicket(), OrderLots(), Bid, slip, clr);
        if (OrderType() == OP_SELL)
            error = OrderClose(OrderTicket(), OrderLots(), Ask, slip, clr);
    }
    UpdateAfterOrder();
}

void Kill()
{
    CloseAllOrders();
    while (AccountBalance() >= initial_deposit - 1)
    {
        error = OrderSend(Symbol(), OP_BUY, 0.01, Ask, 0, 0, 0, 0, 0, 0, 0);
        CloseAllOrders();
    }
    ExpertRemove();
}

void Debug()
{
    UpdateBeforeOrder();
    int time_difference = TimeCurrent() - Time[0];
    Comment("\n- "         +
            "Lots: "       + i_lots                                                    + " - \n" +
            "Timeout: "    + (Time[0] - order__time) / 1                               + " - \n" +
            "Last: "       + last_order_price                                          + " - \n" +
            "Output 1: "   + round(my_network.output_layer[0].output * 10000) / 10000  + " - \n" +
            "Output 2: "   + round(my_network.output_layer[1].output * 10000) / 10000  + " - \n" +
            "Time: "       + time_difference                                           + " - \n" +
            "");
}
