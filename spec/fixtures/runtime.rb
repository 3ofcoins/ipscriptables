iptables do
  table :filter do
    inherit(:FORWARD) { |rule| rule[:i] == 'docker0' || rule[:o] == 'docker0' }
  end
end
