# Download data
vt_data_url = "https://transition.fcc.gov/form477/BroadbandData/Fixed/Dec17/Version%201/VT-Fixed-Dec2017.zip"
nh_data_url = "https://transition.fcc.gov/form477/BroadbandData/Fixed/Dec17/Version%201/NH-Fixed-Dec2017.zip"

require 'open-uri'
IO.copy_stream(open(vt_data_url), 'vt_data.zip')
IO.copy_stream(open(nh_data_url), 'nh_data.zip')
