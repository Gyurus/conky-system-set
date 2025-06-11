Conky (1.19) config with:
Dependencies: sudo apt install vnstat lm-sensors curl nvidia-smi
              sudo sensors-detect


Show top Memory and Cpu using apps
Network graphs and info auto-adapt to the working device
Gpu, Cpu termal info
Weather via wttr.in ${execpi 600 curl -s 'wttr.in/?format=3'} Shows simple one-line weather. If you want detailed weather or a specific city, change it to: ${execpi 600 curl -s 'wttr.in/Dublin?format=3'}
Battery status if exists
ram, swap
Monthly data cap bar from vnstat change here BEGIN{cap=102400}  # 100GB = 102400MB
