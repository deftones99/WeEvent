package com.webank.weevent.sample;

import java.net.MalformedURLException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

import com.webank.weevent.broker.fisco.constant.WeEventConstants;
import com.webank.weevent.sdk.BrokerException;
import com.webank.weevent.sdk.SendResult;
import com.webank.weevent.sdk.jsonrpc.IBrokerRpc;

import com.googlecode.jsonrpc4j.JsonRpcHttpClient;
import com.googlecode.jsonrpc4j.ProxyUtil;

public class JsonRPC {
    private final static String groupId = "1";
    private final static Map<String, String> extensions = new HashMap<>();

    public static void main(String[] args) {

        System.out.println("This is WeEvent json rpc sample.");

        try {
            URL remote = new URL("http://localhost:8080/weevent/jsonrpc");
            // 创建客户端
            JsonRpcHttpClient client = new JsonRpcHttpClient(remote);
            // 实例化rpc对象
            IBrokerRpc rpc = ProxyUtil.createClientProxy(client.getClass().getClassLoader(), IBrokerRpc.class, client);

            // 确认主题存在
            rpc.open("com.weevent.test", groupId);

            // 发布事件，主题“com.weevent.test”，事件内容为"hello weevent"
            extensions.put(WeEventConstants.EXTENSIONS_GROUP_ID, "1");
            SendResult sendResult = rpc.publish("com.weevent.test", groupId, "hello weevent".getBytes(StandardCharsets.UTF_8), extensions);
            System.out.println(sendResult.getStatus());
        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (BrokerException e) {
            e.printStackTrace();
        }
    }
}
