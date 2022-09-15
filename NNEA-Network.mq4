extern float weight_11 = 1;
extern float weight_12 = 1;
extern float weight_13 = 1;
extern float weight_14 = 1;
extern float weight_15 = 1;
extern float threshhold_1 = 1;
extern float weight_21 = 1;
extern float weight_22 = 1;
extern float weight_23 = 1;
extern float weight_24 = 1;
extern float weight_25 = 1;
extern float threshhold_2 = 1;
extern float weight_31 = 1;
extern float weight_32 = 1;
extern float weight_33 = 1;
extern float weight_34 = 1;
extern float weight_35 = 1;
extern float threshhold_3 = 1;
extern float weight_41 = 1;
extern float weight_42 = 1;
extern float weight_43 = 1;
extern float weight_44 = 1;
extern float weight_45 = 1;
extern float threshhold_4 = 1;
extern float o_weight_11 = 1;
extern float o_weight_12 = 1;
extern float o_weight_13 = 1;
extern float o_weight_14 = 1;
extern float o_threshhold_1 = 1;

class Neuron
{
  public:
    float weights[];
    float inputs[];
    float sum_inputs;
    float sum_weights;
    float threshhold;
    float output;

    Neuron(int num_inputs)
    {
        for (int i = 0; i < num_inputs; i++)
        {
            ArrayResize(inputs, num_inputs);
            ArrayResize(weights, num_inputs);
            weights[i] = 1;
        }
    }
};

class Network
{
  public:
    Neuron* input_layer[];
    Neuron* hidden_layer[];
    Neuron* output_layer[];

    Network(int num_input_neurons, int num_hidden_neurons, int num_output_neurons)
    {   // MQL Limitation
        ArrayResize(input_layer, num_input_neurons);
        ArrayResize(hidden_layer, num_hidden_neurons);
        ArrayResize(output_layer, num_output_neurons);
        //---
        
        for (int i = 0; i < num_input_neurons; i++)
        {
            input_layer[i] = new Neuron(1);
            input_layer[i].output = 1;
        }
        
        for (int j = 0; j < num_hidden_neurons; j++)
            hidden_layer[j] = new Neuron(num_input_neurons);
            
        for (int k = 0; k < num_output_neurons; k++)
            output_layer[k] = new Neuron(num_hidden_neurons);
    }
    
    void FeedForward()
    {
        for (int i = 0; i < ArraySize(hidden_layer); ++i)
        {
            hidden_layer[i].sum_inputs = 0;
            hidden_layer[i].sum_weights = 0;

            for (int j = 0; j < ArraySize(input_layer); j++)
            {
                hidden_layer[i].inputs[j] = input_layer[j].output * hidden_layer[i].weights[j];
                hidden_layer[i].sum_inputs  += hidden_layer[i].inputs[j];
                hidden_layer[i].sum_weights += hidden_layer[i].weights[j];
            }

            float average_input = hidden_layer[i].sum_inputs / ArraySize(input_layer);
            hidden_layer[i].output = Sigmoid(average_input - hidden_layer[i].threshhold);
        }
        
        for (int l = 0; l < ArraySize(output_layer); l++)
        {
            output_layer[l].sum_inputs  = 0;
            output_layer[l].sum_weights = 0;
            
            for (int m = 0; m < ArraySize(hidden_layer); m++)
            {
                output_layer[l].inputs[m] = hidden_layer[m].output * output_layer[l].weights[m];
                output_layer[l].sum_inputs  += output_layer[l].inputs[m];
                output_layer[l].sum_weights += output_layer[l].weights[m];
            }
            
            average_input = output_layer[l].sum_inputs / ArraySize(hidden_layer);
            output_layer[l].output = Sigmoid(average_input - output_layer[l].threshhold);
        }
    }
};

float Sigmoid(float n)
{
    return (1 / (1 + exp(-n)) * 1.313034) - 0.156517;
}