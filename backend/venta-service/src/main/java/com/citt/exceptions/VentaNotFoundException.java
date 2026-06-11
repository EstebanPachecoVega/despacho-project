package com.citt.exceptions;

public class VentaNotFoundException extends RuntimeException{
    public VentaNotFoundException(String message) {
        super(message);
    }
}
