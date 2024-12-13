# Using K6 for perf benchmarks

Running a test like below will get you decent results from any linux host. This uses 100 virtual users hitting a single url as fast as they can (can easily change the script in [script.js](script.js) if needed):

```bash
# Testing a public site
TARGET=www.wa.gov.au k6 run script.js 
# Results example

         /\      Grafana   /‾‾/  
    /\  /  \     |\  __   /  /   
   /  \/    \    | |/ /  /   ‾‾\ 
  /          \   |   (  |  (‾)  |
 / __________ \  |_|\_\  \_____/ 

     execution: local
        script: script.js
        output: -

     scenarios: (100.00%) 1 scenario, 100 max VUs, 45s max duration (incl. graceful stop):
              * default: 100 looping VUs for 15s (gracefulStop: 30s)


     data_received..................: 12 GB  814 MB/s
     data_sent......................: 31 MB  2.0 MB/s
     http_req_blocked...............: avg=21.55µs min=130ns   med=341ns   max=39.42ms p(90)=391ns   p(95)=411ns  
     http_req_connecting............: avg=4.21µs  min=0s      med=0s      max=7.69ms  p(90)=0s      p(95)=0s     
     http_req_duration..............: avg=9.51ms  min=7.38ms  med=8.87ms  max=92.18ms p(90)=11.7ms  p(95)=13.12ms
       { expected_response:true }...: avg=9.51ms  min=7.38ms  med=8.87ms  max=92.18ms p(90)=11.7ms  p(95)=13.12ms
     http_req_failed................: 0.00%  0 out of 154160
     http_req_receiving.............: avg=2.14ms  min=67.41µs med=1.72ms  max=73.07ms p(90)=3.58ms  p(95)=4.84ms 
     http_req_sending...............: avg=33.52µs min=8.09µs  med=23.14µs max=8.83ms  p(90)=45.96µs p(95)=61.1µs 
     http_req_tls_handshaking.......: avg=7.77µs  min=0s      med=0s      max=17.42ms p(90)=0s      p(95)=0s     
     http_req_waiting...............: avg=7.33ms  min=1.4ms   med=6.94ms  max=51ms    p(90)=8.63ms  p(95)=9.56ms 
     http_reqs......................: 154160 10271.106905/s
     iteration_duration.............: avg=9.71ms  min=7.5ms   med=9.03ms  max=92.37ms p(90)=11.96ms p(95)=13.43ms
     iterations.....................: 154160 10271.106905/s
     vus............................: 100    min=100         max=100
     vus_max........................: 100    min=100         max=100


running (15.0s), 000/100 VUs, 154160 complete and 0 interrupted iterations
default ✓ [======================================] 100 VUs  15s
```
