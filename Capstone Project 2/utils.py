"""Data loaders and Tensorflow audio prepreocessing functions
"""
import tensorflow as tf
import tensorflow_io as tfio
import numpy as np
import pandas as pd
import pickle
from sklearn.utils import shuffle
from sklearn.preprocessing import MultiLabelBinarizer, LabelEncoder, StandardScaler

@tf.function
def parse_audio_mfcc(filename, label=0, start=0, end=1323000, rate=8000, nfft=512, window=512, stride=256, mels=54, fmin=50, fmax=8000, top_db=80, low_mel=8, high_mel=27):
    """returns MFCC features trimmed to [START:END] sample indexes and scaled to -1 to 1
       for use with Tensorflow Dataset preprocessing
    """    
    audio = tfio.audio.AudioIOTensor(filename, dtype=tf.float32)
   
    audio = audio[start:end] #crop to uniform size
    audio = tf.math.reduce_mean(audio, axis=1) #stereo to mono
    autiio = tfio.audio.resample(rate_in=44100, rate_out=rate)
    spectrogram = tfio.experimental.audio.spectrogram(audio, nfft=nfft, window=windows, stride=stride)
    mel_spectrogram = tfio.experimental.audio.melscale(spectrogram, rate=rate, mels=mels, fmin=fmin, fmax=fmax)
    dbscale_mel_spectrogram = tfio.experimental.audio.dbscale(mel_spectrogram, top_db=top_db)
    mfcc = tf.signal.mfccs_from_log_mel_spectrograms(dbscale_mel_spectrogram)[1:, low_mel:high_mel]
    mfcc = tf.squeeze(mfcc)
    return mfcc, label

@tf.function
def parse_audio(filename, label=0, start=0, end=1323000):
    """returns audio trimmed to [START:END] sample indexes and scaled to -1 to 1
       for use with TensorFlow Dataset preprocessing
    """    
    audio = tfio.audio.AudioIOTensor(filename, dtype=tf.float32)
   
    audio = audio[start:end] #crop to uniform size
    audio = tf.math.reduce_mean(audio, axis=1) #stereo to mono
    #audio = tf.cast(audio, tf.float32) / 32768.0 # scale
    
    return audio, label

def load_mfcc():
    """loads mfccs generated in the Data Wrangling notebook and saved in pickle files
       returns scaled mfcc data and labels in a train/val/test split according to FMA split
    """
      
    #load and clean mfcc data
    fma_single = pickle.load(open("saved/fma_single.p", "rb"))
    mfcc_df=pickle.load(open("saved/mfcc_small.p","rb"))
    mfcc_df.replace([np.inf, -np.inf], np.nan)
    mfcc_df.fillna(method='ffill',inplace=True)
    drop3=pickle.load(open("saved/drop3.p","rb"))
    fma_single.drop(drop3, inplace=True)
    
    #parse into 'small' subset
    subset = fma_single.index[fma_single['subset'] == 'small']
    fma_small=fma_single.loc[subset]
    mfcc_sub=mfcc_df.loc[subset]
    
    #test/val/train split
    train = fma_small.index[fma_small['split'] == 'training']
    val = fma_small.index[fma_small['split'] == 'validation']
    test = fma_small.index[fma_small['split'] == 'test']     
    X_train = mfcc_sub.loc[train].values
    X_val = mfcc_sub.loc[val].values
    X_test = mfcc_sub.loc[test].values
    
    enc=LabelEncoder()
    labels=fma_small['genre_top']
    y_train = enc.fit_transform(labels[train])
    y_val = enc.transform(labels[val])
    y_test = enc.transform(labels[test])
      
    X_train, y_train = shuffle(X_train, y_train, random_state=42)
    
    #scale data
    scaler = StandardScaler(copy=False)
    X_train = scaler.fit_transform(X_train)
    X_val = scaler.transform(X_val)
    X_test = scaler.transform(X_test)
    
    #save original labels for later analysis
    y_labels=enc.inverse_transform(y_test)
   
    return X_train, X_val, X_test, y_train, y_val, y_test, y_labels

