package com.webank.weevent.sdk.jms;


import javax.jms.BytesMessage;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.MessageListener;
import javax.jms.Topic;
import javax.jms.TopicSubscriber;

import lombok.extern.slf4j.Slf4j;

/**
 * WeEvent JMS TopicSubscriber.
 *
 * @author matthewliu
 * @since 2019/03/25
 */
@Slf4j
public class WeEventTopicSubscriber implements TopicSubscriber, CommandDispatcher {
    private WeEventTopic topic;
    private String subscriptionId;

    public String getHeaderId() {
        return headerId;
    }

    public void setHeaderId(String headerId) {
        this.headerId = headerId;
    }

    private String headerId;

    private MessageListener messageListener;

    public WeEventTopicSubscriber(WeEventTopic topic) {
        this.topic = topic;
    }

    public String getSubscriptionId() {
        return subscriptionId;
    }

    public void setSubscriptionId(String subscriptionId) {
        this.subscriptionId = subscriptionId;
    }

    @Override
    public void dispatch(WeEventStompCommand command) {
        BytesMessage bytesMessage = new WeEventBytesMessage();
        try {
            bytesMessage.writeObject(command.getEvent());
            this.messageListener.onMessage(bytesMessage);
        } catch (JMSException e) {
            log.error("write WeEvent into BytesMessage failed");
        }
    }

    // TopicSubscriber override methods

    @Override
    public Topic getTopic() throws JMSException {
        return this.topic;
    }

    @Override
    public boolean getNoLocal() throws JMSException {
        return false;
    }

    // MessageConsumer override methods

    @Override
    public String getMessageSelector() throws JMSException {
        return null;
    }

    @Override
    public MessageListener getMessageListener() throws JMSException {
        return this.messageListener;
    }

    @Override
    public void setMessageListener(MessageListener messageListener) throws JMSException {
        this.messageListener = messageListener;
    }

    @Override
    public Message receive() throws JMSException {
        return null;
    }

    @Override
    public Message receive(long l) throws JMSException {
        return null;
    }

    @Override
    public Message receiveNoWait() throws JMSException {
        return null;
    }

    @Override
    public void close() throws JMSException {

    }
}
