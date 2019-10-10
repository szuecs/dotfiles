package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/hex"
	"io"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
)

func Foo(s string) string {
	return s + "foo"
}

func main() {
	log := logrus.New() // lorus.DebugLevel
	log.Level = logrus.DebugLevel
	log.Debugf("foo: %s", log)

	key, _ := hex.DecodeString("6368616e676520746869732070617373776f726420746f206120736563726574")
	plaintext := []byte("exampleplaintext")

	block, err := aes.NewCipher(key)
	if err != nil {
		panic(err.Error())
	}

	nonceMutex := sync.RWMutex{}
	// Never use more than 2^32 random nonces with a given key because of the risk of a repeat.
	nonce := make([]byte, 12)
	noncePrev := make([]byte, 12)

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		panic(err.Error())
	}

	go func() {
		t := time.Tick(10 * time.Millisecond) // rolling nonce should be done once in a while

		for {
			<-t
			nonceMutex.Lock()
			noncePrev = nonce[:]
			if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
				panic(err.Error())
			}
			nonceMutex.Unlock()
			log.Infoln("changed nonce")
		}
	}()

	for i := 0; i < 10000; i++ {
		nonceMutex.RLock()
		ciphertext := aesgcm.Seal(nil, nonce, plaintext, nil)
		log.Debugf("%x", ciphertext)

		// PLAIN
		plaintext2, err := aesgcm.Open(nil, nonce, ciphertext, nil)
		nonceMutex.RUnlock()

		// test other nonce
		if err != nil || string(plaintext) != string(plaintext2) {
			log.Infof("Failed to decrypt(%d): %v", i, err)
			// PLAIN
			nonceMutex.RLock()
			plaintext2, err = aesgcm.Open(nil, noncePrev, ciphertext, nil)
			nonceMutex.RUnlock()

			if err != nil {
				log.Errorf("Failed to open AES(%d): %v", i, err)
			}
			log.Infoln("used fallback nonce")
			log.Infof("%s", plaintext2)
		}
		log.Debugf("%s", plaintext2)

		time.Sleep(1 * time.Millisecond)
	}
}
