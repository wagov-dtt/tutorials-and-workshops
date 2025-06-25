prereqs:
  brew install restic
  -wget "https://s3.amazonaws.com/mountpoint-s3-release/latest/{{arch()}}/mount-s3.deb"
  -sudo apt-get -y update && sudo apt-get install -y ./mount-s3.deb
  -rm mount-s3.deb

ddev:
    which ddev || curl -fsSL https://ddev.com/install.sh | bash
    ddev config global --use-hardened-images --omit-containers=ddev-ssh-agent,ddev-router
    ddev debug rebuild --service web
    ddev status

vegeta-ddev HOST:
    echo "GET $(ddev describe -j | jq -r .raw.primary_url)/" | vegeta attack -header "Host: {{HOST}}" -duration=10s -rate=500 | vegeta report -type=text

# Load test a local server using a specific Host header (bypasses LB)
# Usage: just vegeta-host HOST=myapp.example.com URL="http://127.0.0.1:8080/path"
vegeta-host HOST URL="http://127.0.0.1":
  which vegeta || brew install vegeta
  awk -v url="{{URL}}" 'BEGIN{srand(); while(1) printf "GET %s?r=%s\n", url, int(rand()*1000000)}' | echo vegeta attack -header "Host: {{HOST}}" -duration=10s -rate=500 | vegeta report -type=text
