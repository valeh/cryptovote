# cryptovote

PoC implementation for the blockchain based election protocol – CryptoVote

* Install required gems
```
bundle install
```

* Start an observer node

```
PORT=7075 ./observer.rb
```

* Access the blockchain

```
curl http://localhost:7075/chain
```

* Vote 

```
./voter.rb -p 000000000000000000000000000000004a0f1e1ec8b44d4bba77616574b177ce -c "Hulk"
```


* Count the votes 

```
./counter.rb -c http://localhost:7075/chain
```