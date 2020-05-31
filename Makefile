converter: converter.v
	iverilog -o converter converter.v

all: converter

clean:
	rm converter